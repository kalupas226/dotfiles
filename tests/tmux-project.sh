#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/ui.sh"

TMUX_PROJECT="${REPO_ROOT}/packages/bin/.local/bin/tmux-project"

fail() {
    warn "$*"
    exit 1
}

write_ghq_wrapper() {
    local wrapper_path="$1"

    cat >"$wrapper_path" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "list" && "${2:-}" == "-p" ]]; then
    printf '%b' "${TMUX_PROJECT_TEST_GHQ_LIST:-}"
    exit 0
fi

printf 'unexpected ghq command: %s\n' "$*" >&2
exit 1
EOF
    chmod +x "$wrapper_path"
}

write_fzf_wrapper() {
    local wrapper_path="$1"
    local fzf_log="$2"

    cat >"$wrapper_path" <<EOF
#!/usr/bin/env bash
set -euo pipefail

printf 'fzf' >>"${fzf_log}"
for arg in "\$@"; do
    printf ' %s' "\$arg" >>"${fzf_log}"
done
printf '\n' >>"${fzf_log}"
cat >/dev/null

exit_code="\${TMUX_PROJECT_TEST_FZF_EXIT:-0}"
if [[ "\$exit_code" != "0" ]]; then
    exit "\$exit_code"
fi

printf '%s\n' "\${TMUX_PROJECT_TEST_FZF_SELECTION:-}"
EOF
    chmod +x "$wrapper_path"
}

write_tmux_wrapper() {
    local wrapper_path="$1"
    local tmux_log="$2"

    cat >"$wrapper_path" <<EOF
#!/usr/bin/env bash
set -euo pipefail

cmd="\${1:-}"
shift || true
printf '%s' "\$cmd" >>"${tmux_log}"
for arg in "\$@"; do
    printf ' %s' "\$arg" >>"${tmux_log}"
done
printf '\n' >>"${tmux_log}"

case "\$cmd" in
    list-sessions)
        if [[ "\${TMUX_PROJECT_TEST_LIST_FAIL:-0}" == "1" ]]; then
            exit 1
        fi
        printf '%b' "\${TMUX_PROJECT_TEST_SESSIONS:-}"
        ;;
    new-session)
        printf '%s\n' "\${TMUX_PROJECT_TEST_NEW_SESSION_ID:-new-session-id}"
        ;;
    switch-client|attach-session)
        ;;
    *)
        printf 'unexpected tmux command: %s\n' "\$cmd" >&2
        exit 1
        ;;
esac
EOF
    chmod +x "$wrapper_path"
}

setup_wrappers() {
    local wrapper_dir="$1"
    local tmux_log="$2"
    local fzf_log="$3"

    write_ghq_wrapper "${wrapper_dir}/ghq"
    write_fzf_wrapper "${wrapper_dir}/fzf" "$fzf_log"
    write_tmux_wrapper "${wrapper_dir}/tmux" "$tmux_log"
}

run_tmux_project() {
    local wrapper_dir="$1"
    shift

    PATH="${wrapper_dir}:$PATH" "$TMUX_PROJECT" "$@"
}

test_creates_and_switches_inside_tmux() {
    local wrapper_dir
    local tmux_log
    local fzf_log
    local tmpdir
    local project_dir

    wrapper_dir="$(mktemp -d /tmp/tmux-project-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-project-log.XXXXXX)"
    fzf_log="$(mktemp /tmp/tmux-project-fzf-log.XXXXXX)"
    tmpdir="$(mktemp -d /tmp/tmux-project-create.XXXXXX)"
    project_dir="${tmpdir}/my-app"
    mkdir -p "$project_dir"
    setup_wrappers "$wrapper_dir" "$tmux_log" "$fzf_log"

    TMUX="/tmp/tmux-test" \
        TMUX_PROJECT_TEST_GHQ_LIST="${project_dir}\n" \
        TMUX_PROJECT_TEST_FZF_SELECTION="$project_dir" \
        TMUX_PROJECT_TEST_NEW_SESSION_ID="\$42" \
        run_tmux_project "$wrapper_dir"

    grep -F "new-session -d -P -F #{session_id} -s my-app -n main -c ${project_dir}" "$tmux_log" >/dev/null ||
        fail "expected tmux-project to create a project session"
    grep -F "switch-client -t \$42" "$tmux_log" >/dev/null ||
        fail "expected tmux-project to switch to the new session inside tmux"
    grep -F "fzf --prompt=project>  --preview=" "$fzf_log" >/dev/null ||
        fail "expected tmux-project to open fzf with a project prompt"

    rm -rf "$wrapper_dir" "$tmux_log" "$fzf_log" "$tmpdir"
}

test_switches_existing_session_inside_tmux() {
    local wrapper_dir
    local tmux_log
    local fzf_log
    local tmpdir
    local project_dir

    wrapper_dir="$(mktemp -d /tmp/tmux-project-existing-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-project-existing-log.XXXXXX)"
    fzf_log="$(mktemp /tmp/tmux-project-existing-fzf-log.XXXXXX)"
    tmpdir="$(mktemp -d /tmp/tmux-project-existing.XXXXXX)"
    project_dir="${tmpdir}/my-app"
    mkdir -p "$project_dir"
    setup_wrappers "$wrapper_dir" "$tmux_log" "$fzf_log"

    TMUX="/tmp/tmux-test" \
        TMUX_PROJECT_TEST_GHQ_LIST="${project_dir}\n" \
        TMUX_PROJECT_TEST_FZF_SELECTION="$project_dir" \
        TMUX_PROJECT_TEST_SESSIONS="my-app\t\$7\n" \
        run_tmux_project "$wrapper_dir"

    if grep -F "new-session" "$tmux_log" >/dev/null; then
        fail "expected tmux-project not to create an existing session"
    fi
    grep -F "switch-client -t \$7" "$tmux_log" >/dev/null ||
        fail "expected tmux-project to switch to the existing session"

    rm -rf "$wrapper_dir" "$tmux_log" "$fzf_log" "$tmpdir"
}

test_creates_and_attaches_outside_tmux() {
    local wrapper_dir
    local tmux_log
    local fzf_log
    local tmpdir
    local project_dir

    wrapper_dir="$(mktemp -d /tmp/tmux-project-attach-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-project-attach-log.XXXXXX)"
    fzf_log="$(mktemp /tmp/tmux-project-attach-fzf-log.XXXXXX)"
    tmpdir="$(mktemp -d /tmp/tmux-project-attach.XXXXXX)"
    project_dir="${tmpdir}/my app:api"
    mkdir -p "$project_dir"
    setup_wrappers "$wrapper_dir" "$tmux_log" "$fzf_log"

    TMUX='' \
        TMUX_PROJECT_TEST_GHQ_LIST="${project_dir}\n" \
        TMUX_PROJECT_TEST_FZF_SELECTION="$project_dir" \
        TMUX_PROJECT_TEST_LIST_FAIL=1 \
        TMUX_PROJECT_TEST_NEW_SESSION_ID="\$9" \
        run_tmux_project "$wrapper_dir"

    grep -F "new-session -d -P -F #{session_id} -s my_app_api -n main -c ${project_dir}" "$tmux_log" >/dev/null ||
        fail "expected tmux-project to sanitize the session name"
    grep -F "attach-session -t \$9" "$tmux_log" >/dev/null ||
        fail "expected tmux-project to attach outside tmux"

    rm -rf "$wrapper_dir" "$tmux_log" "$fzf_log" "$tmpdir"
}

test_cancel_does_not_call_tmux() {
    local wrapper_dir
    local tmux_log
    local fzf_log
    local tmpdir
    local project_dir

    wrapper_dir="$(mktemp -d /tmp/tmux-project-cancel-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-project-cancel-log.XXXXXX)"
    fzf_log="$(mktemp /tmp/tmux-project-cancel-fzf-log.XXXXXX)"
    tmpdir="$(mktemp -d /tmp/tmux-project-cancel.XXXXXX)"
    project_dir="${tmpdir}/my-app"
    mkdir -p "$project_dir"
    setup_wrappers "$wrapper_dir" "$tmux_log" "$fzf_log"

    TMUX="/tmp/tmux-test" \
        TMUX_PROJECT_TEST_GHQ_LIST="${project_dir}\n" \
        TMUX_PROJECT_TEST_FZF_EXIT=130 \
        run_tmux_project "$wrapper_dir"

    if [[ -s "$tmux_log" ]]; then
        fail "expected tmux-project not to call tmux after picker cancellation"
    fi

    rm -rf "$wrapper_dir" "$tmux_log" "$fzf_log" "$tmpdir"
}

main() {
    step "Running tmux-project tests"
    test_creates_and_switches_inside_tmux
    ok "creates and switches to project sessions inside tmux"
    test_switches_existing_session_inside_tmux
    ok "switches to existing project sessions"
    test_creates_and_attaches_outside_tmux
    ok "creates and attaches to project sessions outside tmux"
    test_cancel_does_not_call_tmux
    ok "cancels without calling tmux"
}

main "$@"
