#!/usr/bin/env bash

# Record Claude Code session cwd state for tmux helpers.
# Keep stdout empty so the hook never injects context or decisions.

set -u

input=$(cat)
tmpdir="${TMPDIR:-/tmp}"
state_dir="${tmpdir%/}/claude-cwd-state"

mkdir -p "$state_dir" 2>/dev/null || exit 0

record=$(
    printf '%s' "$input" | jq -c \
        --arg timestamp "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
        --arg claude_project_dir "${CLAUDE_PROJECT_DIR:-}" \
        '{
            timestamp: $timestamp,
            hook_event_name: (.hook_event_name // "" | tostring),
            session_id: (.session_id // "" | tostring),
            project_dir: $claude_project_dir,
            worktree_path: (.worktree.path // "" | tostring),
            workspace_current_dir: (.workspace.current_dir // "" | tostring),
            cwd: (.cwd // "" | tostring),
            old_cwd: (.old_cwd // "" | tostring),
            new_cwd: (.new_cwd // "" | tostring),
            effective_cwd: (.worktree.path // .workspace.current_dir // .new_cwd // .cwd // "" | tostring)
        }' 2>/dev/null
) || exit 0

[ -n "$record" ] || exit 0

session_id=$(printf '%s' "$record" | jq -r '.session_id // ""' 2>/dev/null)
if [ -z "$session_id" ]; then
    session_id="unknown"
fi

safe_session_id=$(printf '%s' "$session_id" | tr -cs '[:alnum:]_.-' '_')

printf '%s\n' "$record" > "$state_dir/session-${safe_session_id}.json" 2>/dev/null || true

exit 0
