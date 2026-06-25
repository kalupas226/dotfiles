#!/usr/bin/env bash
# Claude Code statusLine command
# Layout (Nerd Font icons, see icon_* below):
#   ✳  <dir>  <branch> <dirty><ahead/behind>  <pr>
#   ╰ <model> │ <gauge> <tokens|pct> │ $<cost> │ <elapsed>
# Catppuccin Mocha palette, kept sparse: marker / gauge / dirty are the line-1
# accents and the PR tracks its review state; on line 2 cost is green and
# elapsed yellow, with groups split by a dim │. Everything else is gray so the
# icons carry the meaning.

# --- Helpers ------------------------------------------------------------------
text_len() {
    local LC_ALL=C
    printf '%s' "${#1}"
}

truncate_middle() {
    local value="$1"
    local max_width="$2"
    local value_len
    local head_len
    local tail_len

    value_len="${#value}"
    if [ "$value_len" -le "$max_width" ]; then
        printf '%s' "$value"
        return
    fi

    if [ "$max_width" -le 3 ]; then
        printf '%s' "${value:0:max_width}"
        return
    fi

    head_len=$(((max_width - 3) / 2))
    tail_len=$((max_width - 3 - head_len))
    printf '%s...%s' "${value:0:head_len}" "${value:value_len-tail_len:tail_len}"
}

# colorize <color codes> <text>: wrap text in color, reset afterwards. Colors go
# through %b (not the format string) so escapes expand while text stays literal.
colorize() { printf '%b%s%b' "$1" "$2" "$RESET"; }

build_line1_plain() {
    local dir_part="$1"
    local branch_part="$2"
    local status_part="$3"
    local pr_part="$4"
    # Icons are part of the plain text so width fitting accounts for them; they
    # are prepended after truncation so they are never sliced.
    local line="${marker} ${icon_dir} ${dir_part}"

    if [ -n "$branch_part" ]; then
        line="${line} ${icon_branch} ${branch_part}"
    fi
    if [ -n "$status_part" ]; then
        line="${line} ${status_part}"
    fi
    if [ -n "$pr_part" ]; then
        line="${line} ${pr_part}"
    fi
    printf '%s' "$line"
}

# --- Config -------------------------------------------------------------------
# Use git timeouts when coreutils' gtimeout is available (avoids stalls on huge repos).
if command -v gtimeout >/dev/null 2>&1; then GIT_TIMEOUT="gtimeout 1"; else GIT_TIMEOUT=""; fi

columns="${COLUMNS:-120}"
case "$columns" in
    ''|*[!0-9]*) columns=120 ;;
esac
if [ "$columns" -lt 40 ]; then
    columns=40
fi

marker="✳"

# Nerd Font icons (rendered via the Hack Nerd Font Mono fallback in WezTerm).
# Built from printf octal UTF-8 escapes rather than literal glyphs so the bytes
# survive editing and need no bash 4 unicode-escape support.
icon_dir=$(printf '\357\201\273')       # nf-fa-folder       U+F07B
icon_branch=$(printf '\356\234\245')    # nf-dev-git_branch  U+E725
icon_model=$(printf '\363\260\232\251') # nf-md-robot        U+F06A9
icon_clock=$(printf '\357\200\227')     # nf-fa-clock_o      U+F017
icon_pr=$(printf '\357\220\207')        # nf-oct-git_pull_request  U+F407

# Git status glyphs are plain symbols (not label icons): dirty sits in the same
# group as the ⇡/⇣ ahead/behind arrows, so it stays a simple mark for consistency.
dirty_mark="*"

sep=" │ "                          # line-2 group separator (dim)

# Color is deliberately sparse: icons carry meaning, so only the leading marker,
# the usage gauge, and the dirty marker get an accent. Everything else is gray.
CLAUDE='\033[38;2;217;119;87m'    # #d97757 Claude brand orange (leading marker)
PEACH='\033[38;2;250;179;135m'    # #fab387 dirty marker (sole line-1 accent)
GRAY='\033[38;2;127;132;156m'     # #7f849c paths, branch, model, cost, icons, glyph
GREEN='\033[38;2;166;227;161m'    # #a6e3a1 low usage gauge
YELLOW='\033[38;2;249;226;175m'   # #f9e2af mid usage gauge
RED='\033[38;2;243;139;168m'      # #f38ba8 high usage gauge
TRACK='\033[38;2;69;71;90m'       # #45475a empty gauge track
BOLD='\033[1m'
RESET='\033[0m'

# --- Read Claude statusline input ---------------------------------------------
input=$(cat)

# Pull every field in a single jq pass (the statusLine refreshes often, so one
# process beats five). Fields are joined with US (\037): a non-whitespace
# delimiter so read preserves empty fields. A tab IFS collapses runs of tabs
# (tab is IFS whitespace), which would misalign every field after a missing one.
us=$(printf '\037')
IFS="$us" read -r cwd model used_pct cost_usd duration_ms input_tokens ctx_size pr_number pr_state <<EOF
$(printf '%s' "$input" | jq -r '
def preferred_cwd:
    .worktree.path // .workspace.current_dir // .cwd // "";
[
    preferred_cwd,
    .model.display_name // "",
    .context_window.used_percentage // "",
    .cost.total_cost_usd // "",
    .cost.total_duration_ms // "",
    .context_window.total_input_tokens // "",
    .context_window.context_window_size // "",
    .pr.number // "",
    .pr.review_state // ""
] | map(tostring) | join("\u001f")')
EOF

# --- Directory display ---------------------------------------------------------
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

# --- Git metadata --------------------------------------------------------------
git_branch=""
git_status=""
git_dirty=""
git_ahead=""
git_behind=""
if $GIT_TIMEOUT git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
    git_branch=$($GIT_TIMEOUT git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null \
        || $GIT_TIMEOUT git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)

    if [ -n "$git_branch" ]; then
        dirty=$($GIT_TIMEOUT git -C "$cwd" -c gc.auto=0 status --porcelain 2>/dev/null | head -1)
        [ -n "$dirty" ] && git_dirty="$dirty_mark"

        ahead=$($GIT_TIMEOUT git -C "$cwd" -c gc.auto=0 rev-list --count '@{u}..HEAD' 2>/dev/null || echo "")
        behind=$($GIT_TIMEOUT git -C "$cwd" -c gc.auto=0 rev-list --count 'HEAD..@{u}' 2>/dev/null || echo "")
        [ -n "$ahead" ] && [ "$ahead" -gt 0 ] 2>/dev/null && git_ahead="⇡${ahead}"
        [ -n "$behind" ] && [ "$behind" -gt 0 ] 2>/dev/null && git_behind="⇣${behind}"

        # Plain combined form drives width fitting; colors are applied at render.
        git_status="${git_dirty}${git_ahead}${git_behind}"
    fi
fi

# --- Pull request --------------------------------------------------------------
# Only present once Claude Code has found a PR; color tracks the review state.
pr_plain=""
pr_color="$GRAY"
if [ -n "$pr_number" ]; then
    pr_plain="${icon_pr} #${pr_number}"
    case "$pr_state" in
        approved)          pr_color="$GREEN" ;;
        changes_requested) pr_color="$RED" ;;
    esac
fi

# --- Context gauge -------------------------------------------------------------
# Claude Code can omit used_percentage (e.g. early in a session) while still
# reporting tokens; derive the percentage from tokens so the gauge and the
# token label below still render instead of the whole context group vanishing.
if [ -z "$used_pct" ] && [ -n "$input_tokens" ] && [ -n "$ctx_size" ] && [ "$ctx_size" -gt 0 ] 2>/dev/null; then
    used_pct=$(awk -v u="$input_tokens" -v s="$ctx_size" 'BEGIN { printf "%.4f", (u / s) * 100 }')
fi

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
    i=1
    while [ "$i" -le 8 ]; do
        if [ "$i" -le "$filled" ]; then filled_str="${filled_str}█"; else empty_str="${empty_str}█"; fi
        i=$((i + 1))
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

# Context label: prefer absolute tokens (used/size, rounded to k) when Claude
# Code reports them; otherwise fall back to the bare percentage.
ctx_label=""
[ -n "$used_pct" ] && ctx_label="${used_pct_display}%"
if [ -n "$input_tokens" ] && [ -n "$ctx_size" ] && [ "$ctx_size" -gt 0 ] 2>/dev/null; then
    ctx_label="$(awk -v u="$input_tokens" -v s="$ctx_size" 'BEGIN { printf "%dk/%dk", (u + 500) / 1000, (s + 500) / 1000 }')"
fi

# --- Cost and elapsed ----------------------------------------------------------
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

cost=""
if [ -n "$cost_usd" ]; then
    cost=$(awk -v c="$cost_usd" 'BEGIN { printf "$%.2f", c }')
fi

# --- Fit layout to COLUMNS -----------------------------------------------------
branch_display="$git_branch"
line1_plain=""

if [ -n "$branch_display" ]; then
    branch_cap=$((columns / 3))
    if [ "$branch_cap" -gt 40 ]; then branch_cap=40; fi
    if [ "$branch_cap" -lt 12 ]; then branch_cap=12; fi
    branch_display="$(truncate_middle "$branch_display" "$branch_cap")"
fi

line1_plain="$(build_line1_plain "$short_dir" "$branch_display" "$git_status" "$pr_plain")"
if [ "$(text_len "$line1_plain")" -gt "$columns" ]; then
    diff=$(($(text_len "$line1_plain") - columns))
    dir_cap=$(($(text_len "$short_dir") - diff))
    if [ "$dir_cap" -lt 8 ]; then dir_cap=8; fi
    short_dir="$(truncate_middle "$short_dir" "$dir_cap")"
    line1_plain="$(build_line1_plain "$short_dir" "$branch_display" "$git_status" "$pr_plain")"
fi

if [ "$(text_len "$line1_plain")" -gt "$columns" ] && [ -n "$branch_display" ]; then
    diff=$(($(text_len "$line1_plain") - columns))
    branch_cap=$(($(text_len "$branch_display") - diff))
    if [ "$branch_cap" -lt 8 ]; then branch_cap=8; fi
    branch_display="$(truncate_middle "$branch_display" "$branch_cap")"
    line1_plain="$(build_line1_plain "$short_dir" "$branch_display" "$git_status" "$pr_plain")"
fi

line2_model="$model"
line2_rest=""
if [ -n "$gauge" ] || [ -n "$empty_str" ]; then
    line2_rest="${line2_rest}${sep}${gauge}${empty_str} ${ctx_label}"
fi
if [ -n "$cost" ]; then
    line2_rest="${line2_rest}${sep}${cost}"
fi
if [ -n "$elapsed" ]; then
    line2_rest="${line2_rest}${sep}${icon_clock} ${elapsed}"
fi

# Continuation glyph, plus the model icon when a model is present.
if [ -n "$line2_model" ]; then
    line2_head="╰ ${icon_model} "
else
    line2_head="╰ "
fi
line2_plain="${line2_head}${line2_model}${line2_rest}"
if [ "$(text_len "$line2_plain")" -gt "$columns" ] && [ -n "$line2_model" ]; then
    fixed_len=$(($(text_len "$line2_head") + $(text_len "$line2_rest")))
    model_cap=$((columns - fixed_len))
    if [ "$model_cap" -lt 0 ]; then model_cap=0; fi
    line2_model="$(truncate_middle "$line2_model" "$model_cap")"
fi

# --- Render colored output -----------------------------------------------------
line1=$(colorize "${BOLD}${CLAUDE}" "$marker")
line1="${line1} $(colorize "$GRAY" "$icon_dir") $(colorize "$GRAY" "$short_dir")"
if [ -n "$branch_display" ]; then
    line1="${line1} $(colorize "$GRAY" "$icon_branch") $(colorize "$GRAY" "$branch_display")"
fi
if [ -n "$git_status" ]; then
    status_colored=""
    [ -n "$git_dirty" ] && status_colored="${status_colored}$(colorize "${BOLD}${PEACH}" "$git_dirty")"
    [ -n "$git_ahead" ] && status_colored="${status_colored}$(colorize "$GRAY" "$git_ahead")"
    [ -n "$git_behind" ] && status_colored="${status_colored}$(colorize "$GRAY" "$git_behind")"
    line1="${line1} ${status_colored}"
fi
if [ -n "$pr_plain" ]; then
    line1="${line1} $(colorize "$pr_color" "$pr_plain")"
fi

line2="$(colorize "$GRAY" "$line2_head")"
if [ -n "$line2_model" ]; then
    line2="${line2}$(colorize "$GRAY" "$line2_model")"
fi
if [ -n "$gauge" ] || [ -n "$empty_str" ]; then
    line2="${line2}$(colorize "$TRACK" "$sep")"
    line2="${line2}$(printf '%b%s%b%b%s%b' "$gauge_color" "$gauge" "$RESET" "$TRACK" "$empty_str" "$RESET")"
    line2="${line2} $(colorize "$GRAY" "$ctx_label")"
fi
if [ -n "$cost" ]; then
    line2="${line2}$(colorize "$TRACK" "$sep")$(colorize "$GREEN" "$cost")"
fi
if [ -n "$elapsed" ]; then
    line2="${line2}$(colorize "$TRACK" "$sep")$(colorize "$GRAY" "$icon_clock") $(colorize "$YELLOW" "$elapsed")"
fi

printf "%s\n%s" "$line1" "$line2"
