#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/ui.sh"

GWT="${REPO_ROOT}/packages/bin/.local/bin/gwt"

fail() {
    warn "$*"
    exit 1
}

meta_file_for_task() {
    local repo_root="$1"
    local task="$2"

    printf '%s/.worktrees/.gwt/tasks/%s.tsv\n' \
        "$repo_root" \
        "$(printf '%s' "$task" | shasum | awk '{print $1}')"
}

metadata_field() {
    local metadata_file="$1"
    local field="$2"

    awk -F '\t' -v field="$field" '{ print $field }' "$metadata_file"
}

setup_repo() {
    local repo_root="$1"
    local task="$2"
    local metadata_branch="$3"
    local actual_branch="$4"
    local metadata_agent="${5:-codex}"
    local worktree_path="${repo_root}/.worktrees/${task}"
    local metadata_file

    repo_root="$(cd "$repo_root" && pwd -P)"
    git init -q "$repo_root"
    git -C "$repo_root" config user.name "Test User"
    git -C "$repo_root" config user.email "test@example.com"

    printf 'base\n' >"${repo_root}/README.md"
    git -C "$repo_root" add README.md
    git -C "$repo_root" commit -qm "Initial commit"

    mkdir -p "${repo_root}/.worktrees/.gwt/tasks"
    git -C "$repo_root" worktree add -q -b "$actual_branch" "$worktree_path"

    metadata_file="$(meta_file_for_task "$repo_root" "$task")"
    printf '%s\t%s\t%s\t%s\t%s\n' \
        "$task" \
        "$metadata_agent" \
        "$worktree_path" \
        "$metadata_branch" \
        "$repo_root" >"$metadata_file"
}

write_tmux_wrapper() {
    local wrapper_path="$1"

    cat >"$wrapper_path" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-}"
shift || true

case "$cmd" in
    has-session)
        exit 1
        ;;
    new-session)
        exit 0
        ;;
    list-windows)
        printf '%%root\tproject@root\t\n'
        ;;
    new-window)
        printf '%%1\n'
        ;;
    list-panes)
        printf '%%2\n'
        ;;
    split-window)
        printf '%%3\n'
        ;;
    set-option|rename-window|select-layout|send-keys|select-pane|select-window|switch-client|attach-session|respawn-pane)
        exit 0
        ;;
    *)
        printf 'unexpected tmux command: %s\n' "$cmd" >&2
        exit 1
        ;;
esac
EOF
    chmod +x "$wrapper_path"
}

write_agent_wrapper() {
    local wrapper_path="$1"

    cat >"$wrapper_path" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$wrapper_path"
}

write_existing_window_tmux_wrapper() {
    local wrapper_path="$1"
    local tmux_log="$2"
    local task="$3"
    local agent="$4"

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
    has-session)
        exit 0
        ;;
    list-windows)
        if [[ "\$*" == *"#{window_name}"* ]]; then
            printf '%%root\tproject@root\t\n'
            printf '%%1\t%s\t%s\n' "${task}" "${task}"
        else
            printf '%%root\t\n'
            printf '%%1\t%s\n' "${task}"
        fi
        ;;
    show-options)
        if [[ "\$*" == *"@gwt_agent_pane"* ]]; then
            printf '%%2\n'
            exit 0
        fi
        if [[ "\$*" == *"@gwt_shell_pane"* ]]; then
            printf '%%3\n'
            exit 0
        fi
        if [[ "\$*" == *"@gwt_agent"* ]]; then
            printf '%s\n' "${agent}"
            exit 0
        fi
        exit 1
        ;;
    display-message)
        if [[ "\$*" == *"#{pane_tty}"* ]]; then
            printf '/dev/ttys999\n'
            exit 0
        fi
        if [[ "\$*" == *"#{pane_current_command}"* ]]; then
            printf '%s\n' "${agent}"
            exit 0
        fi
        exit 1
        ;;
    list-panes)
        printf '%%2\n%%3\n'
        ;;
    set-option|rename-window|select-layout|select-pane|select-window|switch-client|attach-session|respawn-pane)
        exit 0
        ;;
    *)
        printf 'unexpected tmux command: %s\n' "\$cmd" >&2
        exit 1
        ;;
esac
EOF
    chmod +x "$wrapper_path"
}

write_ps_wrapper() {
    local wrapper_path="$1"
    local process_name="$2"

    cat >"$wrapper_path" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "${process_name}"
EOF
    chmod +x "$wrapper_path"
}

test_open_updates_stale_branch_metadata_on_default_confirmation() {
    local repo_root
    local task="task-open-stale-update"
    local wrapper_dir
    local metadata_file
    local output

    repo_root="$(mktemp -d /tmp/gwt-open-stale-update.XXXXXX)"
    repo_root="$(cd "$repo_root" && pwd -P)"
    wrapper_dir="$(mktemp -d /tmp/gwt-open-stale-update-wrapper.XXXXXX)"
    wrapper_dir="$(cd "$wrapper_dir" && pwd -P)"

    setup_repo "$repo_root" "$task" "expected-branch" "actual-branch"
    metadata_file="$(meta_file_for_task "$repo_root" "$task")"
    write_tmux_wrapper "${wrapper_dir}/tmux"
    write_agent_wrapper "${wrapper_dir}/codex"

    output="$(cd "$repo_root" && printf '\n' | TMUX=1 PATH="${wrapper_dir}:$PATH" "$GWT" open "$task" 2>&1)"

    [[ "$output" == *"metadata does not match the worktree"* ]] || fail "expected stale metadata prompt"
    [[ "$(metadata_field "$metadata_file" 4)" == "actual-branch" ]] || fail "expected branch metadata to update"
    rm -rf "$repo_root" "$wrapper_dir"
}

test_open_aborts_stale_branch_metadata_on_negative_confirmation() {
    local repo_root
    local task="task-open-stale-abort"
    local wrapper_dir
    local metadata_file
    local output
    local rc

    repo_root="$(mktemp -d /tmp/gwt-open-stale-abort.XXXXXX)"
    repo_root="$(cd "$repo_root" && pwd -P)"
    wrapper_dir="$(mktemp -d /tmp/gwt-open-stale-abort-wrapper.XXXXXX)"
    wrapper_dir="$(cd "$wrapper_dir" && pwd -P)"

    setup_repo "$repo_root" "$task" "expected-branch" "actual-branch"
    metadata_file="$(meta_file_for_task "$repo_root" "$task")"
    write_tmux_wrapper "${wrapper_dir}/tmux"
    write_agent_wrapper "${wrapper_dir}/codex"

    set +e
    output="$(cd "$repo_root" && printf 'n\n' | TMUX=1 PATH="${wrapper_dir}:$PATH" "$GWT" open "$task" 2>&1)"
    rc=$?
    set -e

    [[ "$rc" -ne 0 ]] || fail "expected stale metadata negative confirmation to abort"
    [[ "$output" == *"open aborted"* ]] || fail "expected abort message"
    [[ "$(metadata_field "$metadata_file" 4)" == "expected-branch" ]] || fail "expected branch metadata to remain unchanged"
    rm -rf "$repo_root" "$wrapper_dir"
}

test_open_updates_stale_branch_and_requested_agent_metadata() {
    local repo_root
    local task="task-open-stale-agent"
    local wrapper_dir
    local metadata_file
    local output

    repo_root="$(mktemp -d /tmp/gwt-open-stale-agent.XXXXXX)"
    repo_root="$(cd "$repo_root" && pwd -P)"
    wrapper_dir="$(mktemp -d /tmp/gwt-open-stale-agent-wrapper.XXXXXX)"
    wrapper_dir="$(cd "$wrapper_dir" && pwd -P)"

    setup_repo "$repo_root" "$task" "expected-branch" "actual-branch" "codex"
    metadata_file="$(meta_file_for_task "$repo_root" "$task")"
    write_tmux_wrapper "${wrapper_dir}/tmux"
    write_agent_wrapper "${wrapper_dir}/codex"
    write_agent_wrapper "${wrapper_dir}/claude"

    output="$(cd "$repo_root" && printf 'y\n' | TMUX=1 PATH="${wrapper_dir}:$PATH" "$GWT" open --agent claude "$task" 2>&1)"

    [[ "$output" == *"requested agent: claude"* ]] || fail "expected requested agent in stale metadata prompt"
    [[ "$(metadata_field "$metadata_file" 2)" == "claude" ]] || fail "expected agent metadata to update"
    [[ "$(metadata_field "$metadata_file" 4)" == "actual-branch" ]] || fail "expected branch metadata to update"
    rm -rf "$repo_root" "$wrapper_dir"
}

test_open_rejects_force_option() {
    local repo_root
    local task="task-open-force-rejected"
    local output
    local rc

    repo_root="$(mktemp -d /tmp/gwt-open-force-rejected.XXXXXX)"
    repo_root="$(cd "$repo_root" && pwd -P)"

    setup_repo "$repo_root" "$task" "$task" "$task"

    set +e
    output="$(cd "$repo_root" && "$GWT" open --force "$task" 2>&1)"
    rc=$?
    set -e

    [[ "$rc" -ne 0 ]] || fail "expected open --force to fail"
    [[ "$output" == *"unknown option: --force"* ]] || fail "expected unknown option for --force"
    rm -rf "$repo_root"
}

test_open_agent_updates_metadata_without_stale_prompt() {
    local repo_root
    local task="task-open-agent"
    local wrapper_dir
    local metadata_file
    local output

    repo_root="$(mktemp -d /tmp/gwt-open-agent.XXXXXX)"
    repo_root="$(cd "$repo_root" && pwd -P)"
    wrapper_dir="$(mktemp -d /tmp/gwt-open-agent-wrapper.XXXXXX)"
    wrapper_dir="$(cd "$wrapper_dir" && pwd -P)"

    setup_repo "$repo_root" "$task" "$task" "$task" "codex"
    metadata_file="$(meta_file_for_task "$repo_root" "$task")"
    write_tmux_wrapper "${wrapper_dir}/tmux"
    write_agent_wrapper "${wrapper_dir}/claude"

    output="$(cd "$repo_root" && TMUX=1 PATH="${wrapper_dir}:$PATH" "$GWT" open --agent claude "$task" 2>&1)"

    [[ "$output" != *"metadata does not match the worktree"* ]] || fail "did not expect stale metadata prompt"
    [[ "$(metadata_field "$metadata_file" 2)" == "claude" ]] || fail "expected agent metadata to update"
    rm -rf "$repo_root" "$wrapper_dir"
}

test_open_agent_respawns_and_relabels_existing_window() {
    local repo_root
    local task="task-open-existing-agent"
    local wrapper_dir
    local tmux_log

    repo_root="$(mktemp -d /tmp/gwt-open-existing-agent.XXXXXX)"
    repo_root="$(cd "$repo_root" && pwd -P)"
    wrapper_dir="$(mktemp -d /tmp/gwt-open-existing-agent-wrapper.XXXXXX)"
    wrapper_dir="$(cd "$wrapper_dir" && pwd -P)"
    tmux_log="$(mktemp /tmp/gwt-open-existing-agent-log.XXXXXX)"

    setup_repo "$repo_root" "$task" "$task" "$task" "codex"
    write_existing_window_tmux_wrapper "${wrapper_dir}/tmux" "$tmux_log" "$task" "codex"
    write_agent_wrapper "${wrapper_dir}/claude"
    write_ps_wrapper "${wrapper_dir}/ps" "codex"

    (cd "$repo_root" && TMUX=1 PATH="${wrapper_dir}:$PATH" "$GWT" open --agent claude "$task")

    grep -F "respawn-pane -k -t %2 -c ${repo_root}/.worktrees/${task} claude" "$tmux_log" >/dev/null ||
        fail "expected existing agent pane to respawn with claude"
    grep -F "rename-window -t %1 ${task} [claude:" "$tmux_log" >/dev/null ||
        fail "expected window name to reflect requested agent"
    rm -rf "$repo_root" "$wrapper_dir" "$tmux_log"
}

main() {
    step "Running gwt open tests"
    test_open_updates_stale_branch_metadata_on_default_confirmation
    ok "open repairs stale branch metadata after default confirmation"
    test_open_aborts_stale_branch_metadata_on_negative_confirmation
    ok "open aborts stale branch metadata repair after negative confirmation"
    test_open_updates_stale_branch_and_requested_agent_metadata
    ok "open repairs stale branch metadata and updates requested agent"
    test_open_rejects_force_option
    ok "open rejects --force"
    test_open_agent_updates_metadata_without_stale_prompt
    ok "open --agent updates metadata without stale prompt"
    test_open_agent_respawns_and_relabels_existing_window
    ok "open --agent respawns and relabels existing windows"
}

main "$@"
