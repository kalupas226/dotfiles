tmux_pane_format() {
    local pane_id="$1"
    local format="$2"

    tmux display-message -p -t "$pane_id" "$format" 2>/dev/null || true
}

tmux_claude_state_dir() {
    local tmpdir="${TMPDIR:-/tmp}"

    printf '%s/claude-cwd-state\n' "${tmpdir%/}"
}

tmux_file_mtime() {
    local file="$1"

    stat -f '%m' "$file" 2>/dev/null || stat -c '%Y' "$file" 2>/dev/null || printf '0\n'
}

tmux_path_related() {
    local left="$1"
    local right="$2"

    [[ -n "$left" && -n "$right" ]] || return 1
    [[ "$left" == "$right" || "$left" == "$right"/* || "$right" == "$left"/* ]]
}

tmux_pane_has_claude_agents() {
    local pane_id="$1"
    local pane_tty
    local tty_name

    pane_tty="$(tmux_pane_format "$pane_id" "#{pane_tty}")"
    [[ -n "$pane_tty" ]] || return 1

    tty_name="${pane_tty#/dev/}"
    ps -o command= -t "$tty_name" 2>/dev/null |
        grep -E '(^|/)claude([[:space:]].*)?[[:space:]]agents([[:space:]]|$)' >/dev/null 2>&1 ||
        return 1
}

tmux_latest_claude_cwd() {
    local pane_current_path="$1"
    local dir
    local file
    local cwd
    local project_dir
    local mtime
    local best_mtime=0
    local best_cwd=""
    local us

    command -v jq >/dev/null 2>&1 || return 1

    dir="$(tmux_claude_state_dir)"
    [[ -d "$dir" && -n "$pane_current_path" ]] || return 1

    us=$(printf '\037')
    for file in "$dir"/session-*.json; do
        [[ -f "$file" ]] || continue

        IFS="$us" read -r cwd project_dir <<EOF
$(jq -r '
[
    (.effective_cwd // ""),
    (.project_dir // "")
] | map(tostring) | join("\u001f")
' "$file" 2>/dev/null || true)
EOF

        [[ -n "$cwd" && -d "$cwd" ]] || continue
        if [[ -n "$project_dir" ]]; then
            tmux_path_related "$pane_current_path" "$project_dir" || continue
        else
            tmux_path_related "$pane_current_path" "$cwd" || continue
        fi

        mtime="$(tmux_file_mtime "$file")"
        [[ "$mtime" =~ ^[0-9]+$ ]] || mtime=0
        if (( mtime >= best_mtime )); then
            best_mtime="$mtime"
            best_cwd="$cwd"
        fi
    done

    [[ -n "$best_cwd" ]] || return 1
    printf '%s\n' "$best_cwd"
}

tmux_resolved_cwd() {
    local pane_id="$1"
    local pane_current_path
    local claude_cwd

    pane_current_path="$(tmux_pane_format "$pane_id" "#{pane_current_path}")"
    if tmux_pane_has_claude_agents "$pane_id"; then
        if claude_cwd="$(tmux_latest_claude_cwd "$pane_current_path")" && [[ -n "$claude_cwd" && -d "$claude_cwd" ]]; then
            printf '%s\n' "$claude_cwd"
            return 0
        fi
    fi

    if [[ -n "$pane_current_path" && -d "$pane_current_path" ]]; then
        printf '%s\n' "$pane_current_path"
        return 0
    fi

    printf '%s\n' "$HOME"
}
