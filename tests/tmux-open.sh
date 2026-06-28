#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/ui.sh"

TMUX_OPEN="${REPO_ROOT}/packages/tmux/.local/libexec/tmux/open"

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
        if [[ "\$*" == *"#{pane_current_path}"* ]]; then
            printf '%s\n' "\${TMUX_TEST_PANE_CURRENT_PATH:-}"
            exit 0
        fi
        if [[ "\$*" == *"#{session_id}"* ]]; then
            printf '%s\n' "\${TMUX_TEST_SESSION_ID:-\\$1}"
            exit 0
        fi
        exit 1
        ;;
    display-popup|split-window|new-window)
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

run_tmux_open() {
    local wrapper_dir="$1"
    shift

    PATH="${wrapper_dir}:$PATH" "$TMUX_OPEN" "$@"
}

setup_wrappers() {
    local wrapper_dir="$1"
    local tmux_log="$2"

    write_tmux_wrapper "${wrapper_dir}/tmux" "$tmux_log"
    write_ps_wrapper "${wrapper_dir}/ps"
}

test_uses_latest_matching_claude_cwd_for_popup() {
    local wrapper_dir
    local tmux_log
    local tmpdir
    local project_dir
    local other_project_dir
    local old_cwd
    local expected_cwd
    local other_cwd
    local fallback_cwd

    wrapper_dir="$(mktemp -d /tmp/tmux-open-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-open-log.XXXXXX)"
    tmpdir="$(mktemp -d /tmp/tmux-open-state.XXXXXX)"
    project_dir="$(mktemp -d /tmp/tmux-open-project.XXXXXX)"
    other_project_dir="$(mktemp -d /tmp/tmux-open-other-project.XXXXXX)"
    old_cwd="$(mktemp -d /tmp/tmux-open-old-cwd.XXXXXX)"
    expected_cwd="$(mktemp -d /tmp/tmux-open-expected-cwd.XXXXXX)"
    other_cwd="$(mktemp -d /tmp/tmux-open-other-cwd.XXXXXX)"
    fallback_cwd="$project_dir"
    setup_wrappers "$wrapper_dir" "$tmux_log"

    write_claude_state "$tmpdir" old "$old_cwd" "$project_dir" 202401010000.00
    write_claude_state "$tmpdir" expected "$expected_cwd" "$project_dir" 202401010001.00
    write_claude_state "$tmpdir" other "$other_cwd" "$other_project_dir" 202401010002.00

    TMPDIR="$tmpdir" \
        TMUX_TEST_PS_COMMANDS="claude --dangerously-skip-permissions" \
        TMUX_TEST_PANE_CURRENT_PATH="$fallback_cwd" \
        run_tmux_open "$wrapper_dir" popup-lazygit "%1"

    grep -F "display-popup -t %1 -d ${expected_cwd} -xC -yC -w 85% -h 85% -E lazygit" "$tmux_log" >/dev/null ||
        fail "expected popup-lazygit to use latest matching Claude cwd"

    rm -rf "$wrapper_dir" "$tmux_log" "$tmpdir" "$project_dir" "$other_project_dir" "$old_cwd" "$expected_cwd" "$other_cwd"
}

test_non_claude_pane_uses_pane_current_path() {
    local wrapper_dir
    local tmux_log
    local tmpdir
    local project_dir
    local claude_cwd
    local fallback_cwd

    wrapper_dir="$(mktemp -d /tmp/tmux-open-non-claude-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-open-non-claude-log.XXXXXX)"
    tmpdir="$(mktemp -d /tmp/tmux-open-non-claude-state.XXXXXX)"
    project_dir="$(mktemp -d /tmp/tmux-open-non-claude-project.XXXXXX)"
    claude_cwd="$(mktemp -d /tmp/tmux-open-non-claude-cwd.XXXXXX)"
    fallback_cwd="$project_dir"
    setup_wrappers "$wrapper_dir" "$tmux_log"
    write_claude_state "$tmpdir" ignored "$claude_cwd" "$project_dir" 202401010000.00

    TMPDIR="$tmpdir" \
        TMUX_TEST_PS_COMMANDS="zsh" \
        TMUX_TEST_PANE_CURRENT_PATH="$fallback_cwd" \
        run_tmux_open "$wrapper_dir" split-h "%1"

    grep -F "split-window -h -t %1 -c ${fallback_cwd}" "$tmux_log" >/dev/null ||
        fail "expected split-h to ignore Claude cwd outside claude agents panes"

    rm -rf "$wrapper_dir" "$tmux_log" "$tmpdir" "$project_dir" "$claude_cwd"
}

test_claude_pane_falls_back_when_state_is_missing() {
    local wrapper_dir
    local tmux_log
    local tmpdir
    local fallback_cwd

    wrapper_dir="$(mktemp -d /tmp/tmux-open-missing-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-open-missing-log.XXXXXX)"
    tmpdir="$(mktemp -d /tmp/tmux-open-missing-state.XXXXXX)"
    fallback_cwd="$(mktemp -d /tmp/tmux-open-missing-fallback.XXXXXX)"
    setup_wrappers "$wrapper_dir" "$tmux_log"

    TMPDIR="$tmpdir" \
        TMUX_TEST_PS_COMMANDS="claude agents" \
        TMUX_TEST_PANE_CURRENT_PATH="$fallback_cwd" \
        run_tmux_open "$wrapper_dir" split-v "%1"

    grep -F "split-window -v -t %1 -c ${fallback_cwd}" "$tmux_log" >/dev/null ||
        fail "expected split-v to fall back when Claude state is missing"

    rm -rf "$wrapper_dir" "$tmux_log" "$tmpdir" "$fallback_cwd"
}

test_split_v_lazygit_uses_claude_cwd() {
    local wrapper_dir
    local tmux_log
    local tmpdir
    local project_dir
    local claude_cwd

    wrapper_dir="$(mktemp -d /tmp/tmux-open-split-v-lazygit-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-open-split-v-lazygit-log.XXXXXX)"
    tmpdir="$(mktemp -d /tmp/tmux-open-split-v-lazygit-state.XXXXXX)"
    project_dir="$(mktemp -d /tmp/tmux-open-split-v-lazygit-project.XXXXXX)"
    claude_cwd="$(mktemp -d /tmp/tmux-open-split-v-lazygit-cwd.XXXXXX)"
    setup_wrappers "$wrapper_dir" "$tmux_log"
    write_claude_state "$tmpdir" agent "$claude_cwd" "$project_dir" 202401010000.00

    TMPDIR="$tmpdir" \
        TMUX_TEST_PS_COMMANDS="claude agents" \
        TMUX_TEST_PANE_CURRENT_PATH="$project_dir" \
        run_tmux_open "$wrapper_dir" split-v-lazygit "%1"

    grep -F "split-window -v -t %1 -c ${claude_cwd} lazygit" "$tmux_log" >/dev/null ||
        fail "expected split-v-lazygit to use Claude cwd and launch lazygit"

    rm -rf "$wrapper_dir" "$tmux_log" "$tmpdir" "$project_dir" "$claude_cwd"
}

test_new_window_uses_claude_cwd_and_session_id() {
    local wrapper_dir
    local tmux_log
    local tmpdir
    local project_dir
    local claude_cwd

    wrapper_dir="$(mktemp -d /tmp/tmux-open-new-window-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-open-new-window-log.XXXXXX)"
    tmpdir="$(mktemp -d /tmp/tmux-open-new-window-state.XXXXXX)"
    project_dir="$(mktemp -d /tmp/tmux-open-new-window-project.XXXXXX)"
    claude_cwd="$(mktemp -d /tmp/tmux-open-new-window-cwd.XXXXXX)"
    setup_wrappers "$wrapper_dir" "$tmux_log"
    write_claude_state "$tmpdir" agent "$claude_cwd" "$project_dir" 202401010000.00

    TMPDIR="$tmpdir" \
        TMUX_TEST_PS_COMMANDS="claude agents" \
        TMUX_TEST_PANE_CURRENT_PATH="$project_dir" \
        TMUX_TEST_SESSION_ID="\$9" \
        run_tmux_open "$wrapper_dir" new-window "%1"

    grep -F "new-window -t \$9 -c ${claude_cwd}" "$tmux_log" >/dev/null ||
        fail "expected new-window to use Claude cwd and session id"

    rm -rf "$wrapper_dir" "$tmux_log" "$tmpdir" "$project_dir" "$claude_cwd"
}

main() {
    step "Running tmux-open tests"
    test_uses_latest_matching_claude_cwd_for_popup
    ok "uses latest matching Claude cwd for lazygit popup"
    test_non_claude_pane_uses_pane_current_path
    ok "uses pane_current_path outside claude agents panes"
    test_claude_pane_falls_back_when_state_is_missing
    ok "falls back when Claude state is missing"
    test_split_v_lazygit_uses_claude_cwd
    ok "uses Claude cwd for split-v lazygit"
    test_new_window_uses_claude_cwd_and_session_id
    ok "opens new windows from Claude cwd"
}

main "$@"
