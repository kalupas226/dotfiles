#!/usr/bin/env bash
# Claude Code statusLine command
# Layout: ✳ <dir> <branch> <git status> │ <model> <ctx gauge> <pct> $<cost> <elapsed>
# Palette is Catppuccin Mocha, except the leading marker (Claude brand orange).

input=$(cat)

# Pull every field in a single jq pass (the statusLine refreshes often, so one
# process beats five). Tab-separated; empty strings stand in for missing keys.
IFS=$'\t' read -r cwd model used_pct cost_usd duration_ms <<EOF
$(printf '%s' "$input" | jq -r '[
    .workspace.current_dir // .cwd // "",
    .model.display_name // "",
    .context_window.used_percentage // "",
    .cost.total_cost_usd // "",
    .cost.total_duration_ms // ""
] | @tsv')
EOF

# Use git timeouts when coreutils' gtimeout is available (avoids stalls on huge repos).
if command -v gtimeout >/dev/null 2>&1; then GIT_TIMEOUT="gtimeout 1"; else GIT_TIMEOUT=""; fi

# --- Colors --------------------------------------------------------------------
CLAUDE='\033[38;2;217;119;87m'    # #d97757 Claude brand orange (leading marker)
BLUE='\033[38;2;137;180;250m'     # #89b4fa directory
LAVENDER='\033[38;2;180;190;254m' # #b4befe git branch
GRAY='\033[38;2;127;132;156m'     # #7f849c git status / model / separators
GREEN='\033[38;2;166;227;161m'    # #a6e3a1 low usage / cost
YELLOW='\033[38;2;249;226;175m'   # #f9e2af mid usage / time
RED='\033[38;2;243;139;168m'      # #f38ba8 high usage
TRACK='\033[38;2;69;71;90m'       # #45475a empty gauge track
BOLD='\033[1m'
RESET='\033[0m'

# --- Directory: home as ~, then last 3 components (starship truncation_length) --
dir_display="$cwd"
# The ~ here is an intentional display literal, not a path to expand.
# shellcheck disable=SC2088
case "$dir_display" in
    "$HOME") dir_display="~" ;;
    "$HOME"/*) dir_display="~/${dir_display#"$HOME"/}" ;;
esac
short_dir=$(printf '%s' "$dir_display" | awk -F'/' '{
    n = NF
    if (n <= 3) { print $0 }
    else { print "..." "/" $(n-2) "/" $(n-1) "/" $n }
}')

# --- Git branch + status -------------------------------------------------------
git_branch=""
git_status=""
if $GIT_TIMEOUT git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
    git_branch=$($GIT_TIMEOUT git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null \
        || $GIT_TIMEOUT git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)

    if [ -n "$git_branch" ]; then
        dirty=$($GIT_TIMEOUT git -C "$cwd" -c gc.auto=0 status --porcelain 2>/dev/null | head -1)
        [ -n "$dirty" ] && git_status="!"

        ahead=$($GIT_TIMEOUT git -C "$cwd" -c gc.auto=0 rev-list --count '@{u}..HEAD' 2>/dev/null || echo "")
        behind=$($GIT_TIMEOUT git -C "$cwd" -c gc.auto=0 rev-list --count 'HEAD..@{u}' 2>/dev/null || echo "")
        [ -n "$ahead" ] && [ "$ahead" -gt 0 ] 2>/dev/null && git_status="${git_status}⇡${ahead}"
        [ -n "$behind" ] && [ "$behind" -gt 0 ] 2>/dev/null && git_status="${git_status}⇣${behind}"
    fi
fi

# --- Context gauge: 8-cell bar, colored by usage -------------------------------
gauge=""
gauge_color="$GRAY"
used_pct_display=""
if [ -n "$used_pct" ]; then
    # Claude Code can report a fractional percentage; round to a whole number
    # for display so the gauge label stays compact (e.g. 5.7567...% -> 6%).
    used_pct_display=$(awk -v p="$used_pct" 'BEGIN { printf "%d", p + 0.5 }')
    filled=$(awk -v p="$used_pct" 'BEGIN {
        f = int(p / 100 * 8 + 0.5)
        if (p > 0 && f < 1) f = 1   # never hide a non-zero usage
        if (f > 8) f = 8
        print f
    }')
    filled_str=""
    empty_str=""
    for i in $(seq 1 8); do
        if [ "$i" -le "$filled" ]; then filled_str="${filled_str}█"; else empty_str="${empty_str}█"; fi
    done
    gauge="$filled_str"
    # awk keeps the comparison correct even if the percentage is fractional.
    level=$(awk -v p="$used_pct" 'BEGIN { print (p >= 80) ? "high" : (p >= 50) ? "mid" : "low" }')
    case "$level" in
        high) gauge_color="$RED" ;;
        mid)  gauge_color="$YELLOW" ;;
        *)    gauge_color="$GREEN" ;;
    esac
fi

# --- Elapsed time: ms -> compact h/m/s -----------------------------------------
elapsed=""
if [ -n "$duration_ms" ]; then
    elapsed=$(awk -v ms="$duration_ms" 'BEGIN {
        s = int(ms / 1000)
        h = int(s / 3600); m = int((s % 3600) / 60); sec = s % 60
        if (h > 0)      printf "%dh%dm", h, m
        else if (m > 0) printf "%dm%ds", m, sec
        else            printf "%ds", sec
    }')
fi

# --- Cost ----------------------------------------------------------------------
cost=""
if [ -n "$cost_usd" ]; then
    cost=$(awk -v c="$cost_usd" 'BEGIN { printf "$%.2f", c }')
fi

# --- Assemble ------------------------------------------------------------------
# colorize <color codes> <text> -> wrap text in color, reset afterwards.
# Colors are passed as %b args (not in the format string) so escapes expand
# while user-derived text stays a literal %s.
colorize() { printf '%b%s%b' "$1" "$2" "$RESET"; }

parts=$(colorize "${BOLD}${CLAUDE}" "✳")

# Directory
parts="${parts} $(colorize "${BOLD}${BLUE}" "$short_dir")"

# Branch
if [ -n "$git_branch" ]; then
    parts="${parts} $(colorize "${BOLD}${LAVENDER}" "$git_branch")"
fi

# Git status
if [ -n "$git_status" ]; then
    parts="${parts} $(colorize "${BOLD}${GRAY}" "$git_status")"
fi

# Separator before session info
parts="${parts} $(colorize "$GRAY" "│")"

# Model + context gauge + percentage
if [ -n "$model" ]; then
    parts="${parts} $(colorize "$GRAY" "$model")"
fi
if [ -n "$gauge" ] || [ -n "$empty_str" ]; then
    parts="${parts} $(printf '%b%s%b%b%s%b' "$gauge_color" "$gauge" "$RESET" "$TRACK" "$empty_str" "$RESET")"
    parts="${parts} $(colorize "$GRAY" "${used_pct_display}%")"
fi

# Cost + elapsed time
if [ -n "$cost" ]; then
    parts="${parts} $(colorize "$GREEN" "$cost")"
fi
if [ -n "$elapsed" ]; then
    parts="${parts} $(colorize "$YELLOW" "$elapsed")"
fi

printf "%s" "$parts"
