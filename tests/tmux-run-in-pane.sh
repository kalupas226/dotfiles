#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/ui.sh"

TMUX_RUN_IN_PANE="${REPO_ROOT}/packages/tmux/.local/libexec/tmux/run-in-pane"

fail() {
    warn "$*"
    exit 1
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
        if [[ "\$*" == *"#{pane_tty}"* ]]; then
            printf '%s\n' "\${TMUX_TEST_PANE_TTY:-/dev/ttys999}"
            exit 0
        fi
        if [[ "\$*" == *"#{window_id}"* ]]; then
            printf '%s\n' "\${TMUX_TEST_WINDOW_ID:-@1}"
            exit 0
        fi
        if [[ "\$*" == *"#{pane_current_path}"* ]]; then
            printf '%s\n' "\${TMUX_TEST_PANE_CURRENT_PATH:-}"
            exit 0
        fi
        if [[ "\$*" == *"#{pane_in_mode}"* ]]; then
            printf '%s\n' "\${TMUX_TEST_PANE_IN_MODE:-0}"
            exit 0
        fi
        if [[ "\$*" == *"#{pane_current_command}"* ]]; then
            printf '%s\n' "\${TMUX_TEST_PANE_CURRENT_COMMAND:-zsh}"
            exit 0
        fi
        exit 0
        ;;
    list-panes)
        printf '%s\n' "\${TMUX_TEST_LIST_PANES:-}"
        exit 0
        ;;
    select-pane|send-keys)
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

    cat >"$wrapper_path" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$*" == *"-o command="* && "$*" == *"-t ttys999"* ]]; then
    printf '%s\n' "${TMUX_TEST_PS_COMMANDS:-zsh}"
    exit 0
fi

exit 1
EOF
    chmod +x "$wrapper_path"
}

write_claude_state() {
    local tmpdir="$1"
    local session_id="$2"
    local cwd="$3"
    local project_dir="$4"
    local touch_time="$5"
    local state_dir
    local state_file

    state_dir="${tmpdir%/}/claude-cwd-state"
    state_file="${state_dir}/session-${session_id}.json"
    mkdir -p "$state_dir"

    jq -n \
        --arg session_id "$session_id" \
        --arg project_dir "$project_dir" \
        --arg cwd "$cwd" \
        '{
            session_id: $session_id,
            project_dir: $project_dir,
            effective_cwd: $cwd
        }' >"$state_file"

    touch -t "$touch_time" "$state_file"
}

setup_wrappers() {
    local wrapper_dir="$1"
    local tmux_log="$2"

    write_tmux_wrapper "${wrapper_dir}/tmux" "$tmux_log"
    write_ps_wrapper "${wrapper_dir}/ps"
}

run_tmux_run_in_pane() {
    local wrapper_dir="$1"
    shift

    PATH="${wrapper_dir}:$PATH" "$TMUX_RUN_IN_PANE" "$@"
}

test_below_runs_command_from_claude_cwd() {
    local wrapper_dir
    local tmux_log
    local tmpdir
    local project_dir
    local claude_cwd

    wrapper_dir="$(mktemp -d /tmp/tmux-run-in-pane-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-run-in-pane-log.XXXXXX)"
    tmpdir="$(mktemp -d /tmp/tmux-run-in-pane-state.XXXXXX)"
    project_dir="$(mktemp -d /tmp/tmux-run-in-pane-project.XXXXXX)"
    claude_cwd="$(mktemp -d /tmp/tmux-run-in-pane-cwd.XXXXXX)"
    setup_wrappers "$wrapper_dir" "$tmux_log"
    write_claude_state "$tmpdir" agent "$claude_cwd" "$project_dir" 202401010000.00

    TMPDIR="$tmpdir" \
        TMUX_TEST_PS_COMMANDS="claude agents" \
        TMUX_TEST_PANE_CURRENT_PATH="$project_dir" \
        TMUX_TEST_LIST_PANES=$'%1\t0\t0\t100\t20\n%2\t0\t21\t100\t20' \
        TMUX_TEST_PANE_CURRENT_COMMAND="zsh" \
        run_tmux_run_in_pane "$wrapper_dir" below "%1" lazygit

    grep -F "send-keys -t %2 cd '${claude_cwd}' && 'lazygit' Enter" "$tmux_log" >/dev/null ||
        fail "expected tmux-run-in-pane to send command to the pane below"

    rm -rf "$wrapper_dir" "$tmux_log" "$tmpdir" "$project_dir" "$claude_cwd"
}

test_selects_target_after_success() {
    local wrapper_dir
    local tmux_log
    local tmpdir
    local project_dir
    local claude_cwd

    wrapper_dir="$(mktemp -d /tmp/tmux-run-in-pane-select-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-run-in-pane-select-log.XXXXXX)"
    tmpdir="$(mktemp -d /tmp/tmux-run-in-pane-select-state.XXXXXX)"
    project_dir="$(mktemp -d /tmp/tmux-run-in-pane-select-project.XXXXXX)"
    claude_cwd="$(mktemp -d /tmp/tmux-run-in-pane-select-cwd.XXXXXX)"
    setup_wrappers "$wrapper_dir" "$tmux_log"
    write_claude_state "$tmpdir" agent "$claude_cwd" "$project_dir" 202401010000.00

    TMPDIR="$tmpdir" \
        TMUX_TEST_PS_COMMANDS="claude agents" \
        TMUX_TEST_PANE_CURRENT_PATH="$project_dir" \
        TMUX_TEST_LIST_PANES=$'%1\t0\t0\t100\t20\n%2\t0\t21\t100\t20' \
        TMUX_TEST_PANE_CURRENT_COMMAND="zsh" \
        run_tmux_run_in_pane "$wrapper_dir" --select below "%1" lazygit

    grep -F "send-keys -t %2 cd '${claude_cwd}' && 'lazygit' Enter" "$tmux_log" >/dev/null ||
        fail "expected --select run to send command to the pane below"

    grep -F "select-pane -t %2" "$tmux_log" >/dev/null ||
        fail "expected --select run to select the target pane"

    rm -rf "$wrapper_dir" "$tmux_log" "$tmpdir" "$project_dir" "$claude_cwd"
}

test_below_shell_quotes_command_arguments() {
    local wrapper_dir
    local tmux_log
    local tmpdir
    local project_dir
    local claude_cwd

    wrapper_dir="$(mktemp -d /tmp/tmux-run-in-pane-quote-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-run-in-pane-quote-log.XXXXXX)"
    tmpdir="$(mktemp -d /tmp/tmux-run-in-pane-quote-state.XXXXXX)"
    project_dir="$(mktemp -d /tmp/tmux-run-in-pane-quote-project.XXXXXX)"
    claude_cwd="$(mktemp -d /tmp/tmux-run-in-pane-quote-cwd.XXXXXX)"
    setup_wrappers "$wrapper_dir" "$tmux_log"
    write_claude_state "$tmpdir" agent "$claude_cwd" "$project_dir" 202401010000.00

    TMPDIR="$tmpdir" \
        TMUX_TEST_PS_COMMANDS="claude agents" \
        TMUX_TEST_PANE_CURRENT_PATH="$project_dir" \
        TMUX_TEST_LIST_PANES=$'%1\t0\t0\t100\t20\n%2\t0\t21\t100\t20' \
        TMUX_TEST_PANE_CURRENT_COMMAND="zsh" \
        run_tmux_run_in_pane "$wrapper_dir" below "%1" git commit -m "hello; world" "quote's test"

    grep -F "send-keys -t %2 cd '${claude_cwd}' && 'git' 'commit' '-m' 'hello; world' 'quote'\''s test' Enter" "$tmux_log" >/dev/null ||
        fail "expected tmux-run-in-pane to shell-quote command arguments"

    rm -rf "$wrapper_dir" "$tmux_log" "$tmpdir" "$project_dir" "$claude_cwd"
}

test_below_reports_busy_target_pane() {
    local wrapper_dir
    local tmux_log
    local tmpdir
    local fallback_cwd

    wrapper_dir="$(mktemp -d /tmp/tmux-run-in-pane-busy-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-run-in-pane-busy-log.XXXXXX)"
    tmpdir="$(mktemp -d /tmp/tmux-run-in-pane-busy-state.XXXXXX)"
    fallback_cwd="$(mktemp -d /tmp/tmux-run-in-pane-busy-fallback.XXXXXX)"
    setup_wrappers "$wrapper_dir" "$tmux_log"

    TMPDIR="$tmpdir" \
        TMUX_TEST_PS_COMMANDS="zsh" \
        TMUX_TEST_PANE_CURRENT_PATH="$fallback_cwd" \
        TMUX_TEST_LIST_PANES=$'%1\t0\t0\t100\t20\n%2\t0\t21\t100\t20' \
        TMUX_TEST_PANE_CURRENT_COMMAND="lazygit" \
        run_tmux_run_in_pane "$wrapper_dir" --select below "%1" lazygit

    grep -F "display-message -t %1 tmux/run-in-pane: target pane is busy: lazygit" "$tmux_log" >/dev/null ||
        fail "expected tmux-run-in-pane to display a busy-pane message"

    if grep -F "send-keys" "$tmux_log" >/dev/null; then
        fail "expected tmux-run-in-pane not to send keys to a busy pane"
    fi

    if grep -F "select-pane" "$tmux_log" >/dev/null; then
        fail "expected tmux-run-in-pane not to select a busy pane"
    fi

    rm -rf "$wrapper_dir" "$tmux_log" "$tmpdir" "$fallback_cwd"
}

test_below_reports_pane_mode_as_busy() {
    local wrapper_dir
    local tmux_log
    local tmpdir
    local fallback_cwd

    wrapper_dir="$(mktemp -d /tmp/tmux-run-in-pane-mode-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-run-in-pane-mode-log.XXXXXX)"
    tmpdir="$(mktemp -d /tmp/tmux-run-in-pane-mode-state.XXXXXX)"
    fallback_cwd="$(mktemp -d /tmp/tmux-run-in-pane-mode-fallback.XXXXXX)"
    setup_wrappers "$wrapper_dir" "$tmux_log"

    TMPDIR="$tmpdir" \
        TMUX_TEST_PS_COMMANDS="zsh" \
        TMUX_TEST_PANE_CURRENT_PATH="$fallback_cwd" \
        TMUX_TEST_LIST_PANES=$'%1\t0\t0\t100\t20\n%2\t0\t21\t100\t20' \
        TMUX_TEST_PANE_IN_MODE="1" \
        TMUX_TEST_PANE_CURRENT_COMMAND="zsh" \
        run_tmux_run_in_pane "$wrapper_dir" below "%1" lazygit

    grep -F "display-message -t %1 tmux/run-in-pane: target pane is busy: pane mode" "$tmux_log" >/dev/null ||
        fail "expected tmux-run-in-pane to display a pane-mode message"

    rm -rf "$wrapper_dir" "$tmux_log" "$tmpdir" "$fallback_cwd"
}

test_below_reports_missing_target_as_noop() {
    local wrapper_dir
    local tmux_log
    local tmpdir
    local fallback_cwd

    wrapper_dir="$(mktemp -d /tmp/tmux-run-in-pane-missing-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-run-in-pane-missing-log.XXXXXX)"
    tmpdir="$(mktemp -d /tmp/tmux-run-in-pane-missing-state.XXXXXX)"
    fallback_cwd="$(mktemp -d /tmp/tmux-run-in-pane-missing-fallback.XXXXXX)"
    setup_wrappers "$wrapper_dir" "$tmux_log"

    TMPDIR="$tmpdir" \
        TMUX_TEST_PS_COMMANDS="zsh" \
        TMUX_TEST_PANE_CURRENT_PATH="$fallback_cwd" \
        TMUX_TEST_LIST_PANES=$'%1\t0\t0\t100\t20' \
        run_tmux_run_in_pane "$wrapper_dir" --select below "%1" lazygit

    grep -F "display-message -t %1 tmux/run-in-pane: no target pane: below" "$tmux_log" >/dev/null ||
        fail "expected tmux-run-in-pane to display a missing-target message"

    if grep -F "send-keys" "$tmux_log" >/dev/null; then
        fail "expected tmux-run-in-pane not to send keys when no target pane exists"
    fi

    if grep -F "select-pane" "$tmux_log" >/dev/null; then
        fail "expected tmux-run-in-pane not to select when no target pane exists"
    fi

    rm -rf "$wrapper_dir" "$tmux_log" "$tmpdir" "$fallback_cwd"
}

main() {
    step "Running tmux-run-in-pane tests"
    test_below_runs_command_from_claude_cwd
    ok "runs command in pane below from Claude cwd"
    test_selects_target_after_success
    ok "selects target pane after successful run"
    test_below_shell_quotes_command_arguments
    ok "shell-quotes command arguments"
    test_below_reports_busy_target_pane
    ok "reports when target pane is busy"
    test_below_reports_pane_mode_as_busy
    ok "reports pane mode as busy"
    test_below_reports_missing_target_as_noop
    ok "reports missing target pane as no-op"
}

main "$@"
