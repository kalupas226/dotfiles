#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/ui.sh"

STATUSLINE="${REPO_ROOT}/packages/claude/.claude/statusline-command.sh"

fail() {
    warn "$*"
    exit 1
}

strip_ansi() {
    perl -pe 's/\e\[[0-9;]*m//g'
}

visible_line_count() {
    awk 'END { print NR + 0 }'
}

max_visible_width() {
    awk '{ if (length($0) > max) max = length($0) } END { print max + 0 }'
}

setup_repo() {
    local repo_root="$1"
    local branch="$2"

    git init -q "$repo_root"
    git -C "$repo_root" checkout -q -b "$branch"
    printf 'dirty\n' >"${repo_root}/dirty.txt"
}

mock_input() {
    local cwd="$1"
    local worktree_path="${2:-}"

    jq -n \
        --arg cwd "$cwd" \
        --arg worktree_path "$worktree_path" \
        '{
            workspace: { current_dir: $cwd },
            worktree: (if $worktree_path == "" then null else { path: $worktree_path } end),
            model: { display_name: "Claude Sonnet 4.5 With An Extraordinarily Long Display Name" },
            context_window: { used_percentage: 63.4 },
            cost: { total_cost_usd: 12.3456, total_duration_ms: 3723000 }
        }'
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
        if [[ "\$*" == *"#{pane_current_command}"* ]]; then
            printf 'claude\n'
            exit 0
        fi
        exit 1
        ;;
    set-option)
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

test_statusline_outputs_two_fitted_lines() {
    local repo_root
    local branch
    local output
    local visible

    repo_root="$(mktemp -d /tmp/claude-statusline-long-path.XXXXXX)"
    repo_root="${repo_root}/a-very-long-directory-name/another-long-directory-name/final-project-directory"
    mkdir -p "$repo_root"
    branch="feature/extremely-long-branch-name-for-statusline-width-testing"
    setup_repo "$repo_root" "$branch"

    output="$(mock_input "$repo_root" | COLUMNS=80 bash "$STATUSLINE")"
    visible="$(printf '%s' "$output" | strip_ansi)"

    [[ "$(printf '%s\n' "$visible" | visible_line_count)" == "2" ]] ||
        fail "expected exactly two statusline rows, got: $visible"
    [[ "$(printf '%s\n' "$visible" | max_visible_width)" -le 80 ]] ||
        fail "expected visible statusline width to fit within COLUMNS=80, got: $visible"
    # The model name can be truncated to fit, so assert the grouped layout
    # rendered (dim separators) and the cost survived rather than a brittle
    # model substring.
    [[ "$visible" == *"│"* ]] || fail "expected grouped second row with separators"
    [[ "$visible" == *'$12.35'* ]] || fail "expected rounded cost on second row"

    rm -rf "$(dirname "$(dirname "$(dirname "$repo_root")")")"
}

test_statusline_sets_preferred_cwd_in_tmux() {
    local cwd
    local worktree_path
    local wrapper_dir
    local tmux_log
    local output

    cwd="$(mktemp -d /tmp/claude-statusline-cwd.XXXXXX)"
    worktree_path="$(mktemp -d /tmp/claude-statusline-worktree.XXXXXX)"
    wrapper_dir="$(mktemp -d /tmp/claude-statusline-tmux-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/claude-statusline-tmux-log.XXXXXX)"

    write_tmux_wrapper "${wrapper_dir}/tmux" "$tmux_log"

    output="$(mock_input "$cwd" "$worktree_path" |
        TMUX_PANE="%7" PATH="${wrapper_dir}:$PATH" COLUMNS=80 bash "$STATUSLINE")"

    [[ -n "$output" ]] || fail "expected statusline to keep rendering while syncing tmux cwd"
    grep -F "set-option -p -t %7 @preferred_cwd ${worktree_path}" "$tmux_log" >/dev/null ||
        fail "expected statusline to save worktree path as preferred cwd"
    grep -F "set-option -p -t %7 @preferred_cwd_owner claude" "$tmux_log" >/dev/null ||
        fail "expected statusline to save pane command as preferred cwd owner"
    grep -F "set-option -p -t %7 @preferred_cwd_updated_at" "$tmux_log" >/dev/null ||
        fail "expected statusline to save preferred cwd timestamp"

    rm -rf "$cwd" "$worktree_path" "$wrapper_dir" "$tmux_log"
}

test_statusline_works_outside_tmux() {
    local cwd
    local output
    local visible

    cwd="$(mktemp -d /tmp/claude-statusline-outside.XXXXXX)"
    # Drop both pane hints so the sync truly no-ops (and never touches a real pane).
    output="$(mock_input "$cwd" | env -u TMUX_PANE -u CLAUDE_TMUX_PANE COLUMNS=80 bash "$STATUSLINE")"
    visible="$(printf '%s' "$output" | strip_ansi)"

    [[ "$(printf '%s\n' "$visible" | visible_line_count)" == "2" ]] ||
        fail "expected statusline to render two rows outside tmux"

    rm -rf "$cwd"
}

test_statusline_uses_claude_tmux_pane_when_tmux_pane_absent() {
    local cwd
    local worktree_path
    local wrapper_dir
    local tmux_log

    cwd="$(mktemp -d /tmp/claude-statusline-cpane-cwd.XXXXXX)"
    worktree_path="$(mktemp -d /tmp/claude-statusline-cpane-wt.XXXXXX)"
    wrapper_dir="$(mktemp -d /tmp/claude-statusline-cpane-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/claude-statusline-cpane-log.XXXXXX)"
    write_tmux_wrapper "${wrapper_dir}/tmux" "$tmux_log"

    # Claude Code does not pass TMUX_PANE but exports CLAUDE_TMUX_PANE; the sync
    # must fall back to it (agent view / child sessions).
    mock_input "$cwd" "$worktree_path" |
        env -u TMUX_PANE CLAUDE_TMUX_PANE="%9" PATH="${wrapper_dir}:$PATH" COLUMNS=80 bash "$STATUSLINE" >/dev/null

    grep -F "set-option -p -t %9 @preferred_cwd ${worktree_path}" "$tmux_log" >/dev/null ||
        fail "expected statusline to use CLAUDE_TMUX_PANE when TMUX_PANE is absent"

    rm -rf "$cwd" "$worktree_path" "$wrapper_dir" "$tmux_log"
}

test_statusline_shows_context_tokens() {
    local cwd
    local visible

    cwd="$(mktemp -d /tmp/claude-statusline-tokens.XXXXXX)"
    visible="$(jq -n --arg cwd "$cwd" '{
            workspace: { current_dir: $cwd },
            model: { display_name: "Sonnet 4.6" },
            context_window: { used_percentage: 60, total_input_tokens: 120000, context_window_size: 200000 },
            cost: { total_cost_usd: 1, total_duration_ms: 60000 }
        }' | COLUMNS=120 bash "$STATUSLINE" | strip_ansi)"

    [[ "$visible" == *"120k/200k"* ]] ||
        fail "expected token usage (used/size) when Claude Code reports tokens, got: $visible"

    rm -rf "$cwd"
}

test_statusline_shows_tokens_without_percentage() {
    local cwd
    local visible

    cwd="$(mktemp -d /tmp/claude-statusline-tokens-only.XXXXXX)"
    # used_percentage omitted (as Claude Code may early in a session): the gauge
    # and token label must still render by deriving the percentage from tokens.
    visible="$(jq -n --arg cwd "$cwd" '{
            workspace: { current_dir: $cwd },
            model: { display_name: "Sonnet 4.6" },
            context_window: { total_input_tokens: 120000, context_window_size: 200000 },
            cost: { total_cost_usd: 1, total_duration_ms: 60000 }
        }' | COLUMNS=120 bash "$STATUSLINE" | strip_ansi)"

    [[ "$visible" == *"120k/200k"* ]] ||
        fail "expected token usage to render even without used_percentage, got: $visible"

    rm -rf "$cwd"
}

test_statusline_falls_back_to_percentage_without_tokens() {
    local cwd
    local visible

    cwd="$(mktemp -d /tmp/claude-statusline-pct.XXXXXX)"
    visible="$(jq -n --arg cwd "$cwd" '{
            workspace: { current_dir: $cwd },
            model: { display_name: "Sonnet 4.6" },
            context_window: { used_percentage: 60 },
            cost: { total_cost_usd: 1, total_duration_ms: 60000 }
        }' | COLUMNS=120 bash "$STATUSLINE" | strip_ansi)"

    [[ "$visible" == *"60%"* ]] ||
        fail "expected percentage fallback when tokens are absent, got: $visible"

    rm -rf "$cwd"
}

test_statusline_shows_pull_request() {
    local cwd
    local visible

    cwd="$(mktemp -d /tmp/claude-statusline-pr.XXXXXX)"
    visible="$(jq -n --arg cwd "$cwd" '{
            workspace: { current_dir: $cwd },
            model: { display_name: "Sonnet 4.6" },
            context_window: { used_percentage: 60 },
            cost: { total_cost_usd: 1, total_duration_ms: 60000 },
            pr: { number: 123, review_state: "approved" }
        }' | COLUMNS=120 bash "$STATUSLINE" | strip_ansi)"

    [[ "$visible" == *"#123"* ]] ||
        fail "expected PR number on the first row when Claude Code reports a PR, got: $visible"

    rm -rf "$cwd"
}

main() {
    step "Running Claude statusline tests"
    test_statusline_outputs_two_fitted_lines
    ok "statusline renders two fitted rows"
    test_statusline_sets_preferred_cwd_in_tmux
    ok "statusline records preferred cwd in tmux"
    test_statusline_works_outside_tmux
    ok "statusline works outside tmux"
    test_statusline_uses_claude_tmux_pane_when_tmux_pane_absent
    ok "statusline uses CLAUDE_TMUX_PANE when TMUX_PANE is absent"
    test_statusline_shows_context_tokens
    ok "statusline shows context tokens when available"
    test_statusline_shows_tokens_without_percentage
    ok "statusline shows tokens even without used_percentage"
    test_statusline_falls_back_to_percentage_without_tokens
    ok "statusline falls back to percentage without tokens"
    test_statusline_shows_pull_request
    ok "statusline shows PR number when available"
}

main "$@"
