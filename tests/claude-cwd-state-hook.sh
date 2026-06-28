#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/ui.sh"

HOOK="${REPO_ROOT}/packages/claude/.claude/hooks/record-cwd-state.sh"

fail() {
    warn "$*"
    exit 1
}

test_records_minimal_worktree_state() {
    local tmpdir
    local project_dir
    local cwd
    local worktree_path
    local output
    local session_file
    local state_dir_mode
    local session_file_mode

    tmpdir="$(mktemp -d /tmp/claude-cwd-hook-state.XXXXXX)"
    project_dir="$(mktemp -d /tmp/claude-cwd-hook-project.XXXXXX)"
    cwd="$(mktemp -d /tmp/claude-cwd-hook-cwd.XXXXXX)"
    worktree_path="$(mktemp -d /tmp/claude-cwd-hook-worktree.XXXXXX)"

    output="$(jq -n \
        --arg cwd "$cwd" \
        --arg worktree_path "$worktree_path" \
        '{
            hook_event_name: "UserPromptSubmit",
            session_id: "session-worktree",
            cwd: $cwd,
            worktree: { path: $worktree_path },
            transcript_path: "/tmp/ignored.jsonl",
            permission_mode: "default"
        }' |
        TMPDIR="$tmpdir" CLAUDE_PROJECT_DIR="$project_dir" bash "$HOOK")"

    [[ -z "$output" ]] || fail "expected hook stdout to stay empty"

    session_file="${tmpdir%/}/claude-cwd-state/session-session-worktree.json"
    [[ -f "$session_file" ]] || fail "expected session state to be written"
    [[ ! -f "${tmpdir%/}/claude-cwd-state/latest.json" ]] || fail "expected hook not to write latest.json"
    [[ ! -f "${tmpdir%/}/claude-cwd-state/events.jsonl" ]] || fail "expected hook not to append events.jsonl"
    state_dir_mode="$(stat -f '%Lp' "${tmpdir%/}/claude-cwd-state" 2>/dev/null || stat -c '%a' "${tmpdir%/}/claude-cwd-state")"
    session_file_mode="$(stat -f '%Lp' "$session_file" 2>/dev/null || stat -c '%a' "$session_file")"
    [[ "$state_dir_mode" == "700" ]] || fail "expected state directory mode 700, got: $state_dir_mode"
    [[ "$session_file_mode" == "600" ]] || fail "expected session file mode 600, got: $session_file_mode"

    jq -e \
        --arg project_dir "$project_dir" \
        --arg cwd "$cwd" \
        --arg worktree_path "$worktree_path" \
        '
            .project_dir == $project_dir
            and .cwd == $cwd
            and .worktree_path == $worktree_path
            and .effective_cwd == $worktree_path
            and (has("transcript_path") | not)
            and (has("env") | not)
        ' "$session_file" >/dev/null ||
        fail "expected minimal state with worktree cwd priority"

    rm -rf "$tmpdir" "$project_dir" "$cwd" "$worktree_path"
}

test_records_cwd_changed_state() {
    local tmpdir
    local project_dir
    local old_cwd
    local new_cwd
    local session_file

    tmpdir="$(mktemp -d /tmp/claude-cwd-hook-cwdchanged-state.XXXXXX)"
    project_dir="$(mktemp -d /tmp/claude-cwd-hook-cwdchanged-project.XXXXXX)"
    old_cwd="$(mktemp -d /tmp/claude-cwd-hook-old.XXXXXX)"
    new_cwd="$(mktemp -d /tmp/claude-cwd-hook-new.XXXXXX)"

    jq -n \
        --arg old_cwd "$old_cwd" \
        --arg new_cwd "$new_cwd" \
        '{
            hook_event_name: "CwdChanged",
            session_id: "session-cwdchanged",
            cwd: $old_cwd,
            old_cwd: $old_cwd,
            new_cwd: $new_cwd
        }' |
        TMPDIR="$tmpdir" CLAUDE_PROJECT_DIR="$project_dir" bash "$HOOK" >/dev/null

    session_file="${tmpdir%/}/claude-cwd-state/session-session-cwdchanged.json"
    jq -e \
        --arg new_cwd "$new_cwd" \
        '.hook_event_name == "CwdChanged" and .effective_cwd == $new_cwd' "$session_file" >/dev/null ||
        fail "expected CwdChanged state to use new_cwd"

    rm -rf "$tmpdir" "$project_dir" "$old_cwd" "$new_cwd"
}

test_records_stop_state() {
    local tmpdir
    local project_dir
    local cwd
    local session_file

    tmpdir="$(mktemp -d /tmp/claude-cwd-hook-stop-state.XXXXXX)"
    project_dir="$(mktemp -d /tmp/claude-cwd-hook-stop-project.XXXXXX)"
    cwd="$(mktemp -d /tmp/claude-cwd-hook-stop-cwd.XXXXXX)"

    jq -n \
        --arg cwd "$cwd" \
        '{
            hook_event_name: "Stop",
            session_id: "session-stop",
            cwd: $cwd,
            stop_hook_active: false,
            last_assistant_message: "ignored"
        }' |
        TMPDIR="$tmpdir" CLAUDE_PROJECT_DIR="$project_dir" bash "$HOOK" >/dev/null

    session_file="${tmpdir%/}/claude-cwd-state/session-session-stop.json"

    jq -e \
        --arg cwd "$cwd" \
        '.hook_event_name == "Stop"
            and .cwd == $cwd
            and .effective_cwd == $cwd
            and (has("last_assistant_message") | not)' "$session_file" >/dev/null ||
        fail "expected Stop state to record cwd without assistant message"

    rm -rf "$tmpdir" "$project_dir" "$cwd"
}

main() {
    step "Running Claude cwd state hook tests"
    test_records_minimal_worktree_state
    ok "records minimal worktree state"
    test_records_cwd_changed_state
    ok "records CwdChanged state"
    test_records_stop_state
    ok "records Stop state"
}

main "$@"
