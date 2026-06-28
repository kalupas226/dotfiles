#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/ui.sh"

TMUX_FILE_REFS="${REPO_ROOT}/packages/tmux/.local/libexec/tmux/file-refs"

fail() {
    warn "$*"
    exit 1
}

write_git_wrapper() {
    local wrapper_path="$1"

    cat >"$wrapper_path" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-C" && "${3:-}" == "rev-parse" && "${4:-}" == "--show-toplevel" ]]; then
    if [[ "${TMUX_FILE_REFS_TEST_GIT_FAIL:-0}" == "1" ]]; then
        exit 1
    fi
    printf '%s\n' "${TMUX_FILE_REFS_TEST_GIT_ROOT:-$2}"
    exit 0
fi

printf 'unexpected git command: %s\n' "$*" >&2
exit 1
EOF
    chmod +x "$wrapper_path"
}

write_rg_wrapper() {
    local wrapper_path="$1"

    cat >"$wrapper_path" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "--files" ]]; then
    printf '%b' "${TMUX_FILE_REFS_TEST_RG_FILES:-}"
    exit 0
fi

printf 'unexpected rg command: %s\n' "$*" >&2
exit 1
EOF
    chmod +x "$wrapper_path"
}

write_fzf_wrapper() {
    local wrapper_path="$1"
    local fzf_log="$2"
    local fzf_input="$3"

    cat >"$wrapper_path" <<EOF
#!/usr/bin/env bash
set -euo pipefail

printf 'fzf' >>"${fzf_log}"
for arg in "\$@"; do
    printf ' %s' "\$arg" >>"${fzf_log}"
done
printf '\n' >>"${fzf_log}"
cat >"${fzf_input}"

exit_code="\${TMUX_FILE_REFS_TEST_FZF_EXIT:-0}"
if [[ "\$exit_code" != "0" ]]; then
    exit "\$exit_code"
fi

printf '%b' "\${TMUX_FILE_REFS_TEST_FZF_SELECTION:-}"
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
    display-message)
        if [[ "\$*" == *"#{pane_current_path}"* ]]; then
            printf '%s\n' "\${TMUX_FILE_REFS_TEST_PANE_CURRENT_PATH:-}"
        fi
        ;;
    display-popup|set-buffer|paste-buffer)
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
    local fzf_input="$4"

    write_git_wrapper "${wrapper_dir}/git"
    write_rg_wrapper "${wrapper_dir}/rg"
    write_fzf_wrapper "${wrapper_dir}/fzf" "$fzf_log" "$fzf_input"
    write_tmux_wrapper "${wrapper_dir}/tmux" "$tmux_log"
}

run_tmux_file_refs() {
    local wrapper_dir="$1"
    shift

    PATH="${wrapper_dir}:$PATH" "$TMUX_FILE_REFS" "$@"
}

test_opens_popup_from_git_root() {
    local wrapper_dir
    local tmux_log
    local fzf_log
    local fzf_input
    local tmpdir
    local repo_root
    local pane_cwd

    wrapper_dir="$(mktemp -d /tmp/tmux-file-refs-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-file-refs-log.XXXXXX)"
    fzf_log="$(mktemp /tmp/tmux-file-refs-fzf-log.XXXXXX)"
    fzf_input="$(mktemp /tmp/tmux-file-refs-fzf-input.XXXXXX)"
    tmpdir="$(mktemp -d /tmp/tmux-file-refs-root.XXXXXX)"
    repo_root="${tmpdir}/repo"
    pane_cwd="${repo_root}/packages/tmux"
    mkdir -p "$pane_cwd"
    setup_wrappers "$wrapper_dir" "$tmux_log" "$fzf_log" "$fzf_input"

    TMUX_FILE_REFS_TEST_PANE_CURRENT_PATH="$pane_cwd" \
        TMUX_FILE_REFS_TEST_GIT_ROOT="$repo_root" \
        run_tmux_file_refs "$wrapper_dir" "%1"

    grep -F "display-popup -t %1 -d ${repo_root} -xC -yC -w 85% -h 85% -T  file refs  -E " "$tmux_log" >/dev/null ||
        fail "expected file-refs to open a popup from the git root"

    rm -rf "$wrapper_dir" "$tmux_log" "$fzf_log" "$fzf_input" "$tmpdir"
}

test_falls_back_to_current_path_outside_git() {
    local wrapper_dir
    local tmux_log
    local fzf_log
    local fzf_input
    local pane_cwd

    wrapper_dir="$(mktemp -d /tmp/tmux-file-refs-fallback-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-file-refs-fallback-log.XXXXXX)"
    fzf_log="$(mktemp /tmp/tmux-file-refs-fallback-fzf-log.XXXXXX)"
    fzf_input="$(mktemp /tmp/tmux-file-refs-fallback-fzf-input.XXXXXX)"
    pane_cwd="$(mktemp -d /tmp/tmux-file-refs-fallback-cwd.XXXXXX)"
    setup_wrappers "$wrapper_dir" "$tmux_log" "$fzf_log" "$fzf_input"

    TMUX_FILE_REFS_TEST_PANE_CURRENT_PATH="$pane_cwd" \
        TMUX_FILE_REFS_TEST_GIT_FAIL=1 \
        run_tmux_file_refs "$wrapper_dir" "%1"

    grep -F "display-popup -t %1 -d ${pane_cwd} -xC -yC -w 85% -h 85% -T  file refs  -E " "$tmux_log" >/dev/null ||
        fail "expected file-refs to fall back to the pane current path"

    rm -rf "$wrapper_dir" "$tmux_log" "$fzf_log" "$fzf_input" "$pane_cwd"
}

test_refuses_broad_fallback_root_outside_git() {
    local wrapper_dir
    local tmux_log
    local fzf_log
    local fzf_input

    wrapper_dir="$(mktemp -d /tmp/tmux-file-refs-broad-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-file-refs-broad-log.XXXXXX)"
    fzf_log="$(mktemp /tmp/tmux-file-refs-broad-fzf-log.XXXXXX)"
    fzf_input="$(mktemp /tmp/tmux-file-refs-broad-fzf-input.XXXXXX)"
    setup_wrappers "$wrapper_dir" "$tmux_log" "$fzf_log" "$fzf_input"

    TMUX_FILE_REFS_TEST_PANE_CURRENT_PATH="/" \
        TMUX_FILE_REFS_TEST_GIT_FAIL=1 \
        run_tmux_file_refs "$wrapper_dir" "%1"

    grep -F "display-message -t %1 tmux/file-refs: not in a git repo: /" "$tmux_log" >/dev/null ||
        fail "expected file-refs to report broad fallback roots outside git"
    if grep -F "display-popup" "$tmux_log" >/dev/null; then
        fail "expected file-refs not to open a popup from a broad fallback root"
    fi

    rm -rf "$wrapper_dir" "$tmux_log" "$fzf_log" "$fzf_input"
}

test_pick_pastes_backtick_refs() {
    local backtick
    local expected_refs
    local wrapper_dir
    local tmux_log
    local fzf_log
    local fzf_input
    local root

    wrapper_dir="$(mktemp -d /tmp/tmux-file-refs-pick-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-file-refs-pick-log.XXXXXX)"
    fzf_log="$(mktemp /tmp/tmux-file-refs-pick-fzf-log.XXXXXX)"
    fzf_input="$(mktemp /tmp/tmux-file-refs-pick-fzf-input.XXXXXX)"
    root="$(mktemp -d /tmp/tmux-file-refs-pick-root.XXXXXX)"
    setup_wrappers "$wrapper_dir" "$tmux_log" "$fzf_log" "$fzf_input"
    backtick="$(printf '\140')"
    expected_refs="set-buffer -b tmux-file-refs ${backtick}packages/tmux/.tmux.conf${backtick} ${backtick}docs/file name.md${backtick}"

    TMUX_FILE_REFS_TEST_RG_FILES=$'packages/tmux/.tmux.conf\ndocs/file name.md\n' \
        TMUX_FILE_REFS_TEST_FZF_SELECTION=$'packages/tmux/.tmux.conf\ndocs/file name.md\n' \
        run_tmux_file_refs "$wrapper_dir" --pick "%1" "$root"

    grep -F "packages/tmux/.tmux.conf" "$fzf_input" >/dev/null ||
        fail "expected file list to be passed to fzf"
    grep -F -- "--multi" "$fzf_log" >/dev/null ||
        fail "expected fzf to allow multi-select"
    grep -F "$expected_refs" "$tmux_log" >/dev/null ||
        fail "expected file-refs to paste backtick-wrapped path references"
    grep -F "paste-buffer -t %1 -b tmux-file-refs" "$tmux_log" >/dev/null ||
        fail "expected file-refs to paste into the source pane"

    rm -rf "$wrapper_dir" "$tmux_log" "$fzf_log" "$fzf_input" "$root"
}

test_pick_excludes_sensitive_files() {
    local wrapper_dir
    local tmux_log
    local fzf_log
    local fzf_input
    local root

    wrapper_dir="$(mktemp -d /tmp/tmux-file-refs-sensitive-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-file-refs-sensitive-log.XXXXXX)"
    fzf_log="$(mktemp /tmp/tmux-file-refs-sensitive-fzf-log.XXXXXX)"
    fzf_input="$(mktemp /tmp/tmux-file-refs-sensitive-fzf-input.XXXXXX)"
    root="$(mktemp -d /tmp/tmux-file-refs-sensitive-root.XXXXXX)"
    mkdir -p "${root}/config" "${root}/certs" "${root}/.ssh" "${root}/src"
    printf 'secret\n' >"${root}/.env"
    printf 'secret\n' >"${root}/config/.env.local"
    printf 'secret\n' >"${root}/certs/dev.pem"
    printf 'secret\n' >"${root}/certs/dev.key"
    printf 'secret\n' >"${root}/.npmrc"
    printf 'secret\n' >"${root}/.ssh/config"
    printf 'ok\n' >"${root}/src/app.txt"
    setup_wrappers "$wrapper_dir" "$tmux_log" "$fzf_log" "$fzf_input"

    rm -f "${wrapper_dir}/rg"
    TMUX_FILE_REFS_TEST_FZF_SELECTION=$'src/app.txt\n' \
        run_tmux_file_refs "$wrapper_dir" --pick "%1" "$root"

    grep -F "src/app.txt" "$fzf_input" >/dev/null ||
        fail "expected normal files to be listed"
    for path in ".env" "config/.env.local" "certs/dev.pem" "certs/dev.key" ".npmrc" ".ssh/config"; do
        if grep -F "$path" "$fzf_input" >/dev/null; then
            fail "expected sensitive path to be excluded from file refs: $path"
        fi
    done

    rm -rf "$wrapper_dir" "$tmux_log" "$fzf_log" "$fzf_input" "$root"
}

test_pick_cancel_does_not_paste() {
    local wrapper_dir
    local tmux_log
    local fzf_log
    local fzf_input
    local root

    wrapper_dir="$(mktemp -d /tmp/tmux-file-refs-cancel-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-file-refs-cancel-log.XXXXXX)"
    fzf_log="$(mktemp /tmp/tmux-file-refs-cancel-fzf-log.XXXXXX)"
    fzf_input="$(mktemp /tmp/tmux-file-refs-cancel-fzf-input.XXXXXX)"
    root="$(mktemp -d /tmp/tmux-file-refs-cancel-root.XXXXXX)"
    setup_wrappers "$wrapper_dir" "$tmux_log" "$fzf_log" "$fzf_input"

    TMUX_FILE_REFS_TEST_RG_FILES=$'packages/tmux/.tmux.conf\n' \
        TMUX_FILE_REFS_TEST_FZF_EXIT=130 \
        run_tmux_file_refs "$wrapper_dir" --pick "%1" "$root"

    if grep -F "set-buffer" "$tmux_log" >/dev/null; then
        fail "expected file-refs not to set a buffer after picker cancellation"
    fi
    if grep -F "paste-buffer" "$tmux_log" >/dev/null; then
        fail "expected file-refs not to paste after picker cancellation"
    fi

    rm -rf "$wrapper_dir" "$tmux_log" "$fzf_log" "$fzf_input" "$root"
}

main() {
    step "Running tmux-file-refs tests"
    test_opens_popup_from_git_root
    ok "opens popup from the active pane git root"
    test_falls_back_to_current_path_outside_git
    ok "falls back to pane current path outside git"
    test_refuses_broad_fallback_root_outside_git
    ok "refuses broad fallback roots outside git"
    test_pick_pastes_backtick_refs
    ok "pastes selected file references"
    test_pick_excludes_sensitive_files
    ok "excludes sensitive file references"
    test_pick_cancel_does_not_paste
    ok "cancels without pasting"
}

main "$@"
