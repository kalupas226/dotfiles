# Tune fast-syntax-highlighting to better match the shell palette.
typeset -gA FAST_HIGHLIGHT_STYLES
FAST_HIGHLIGHT_STYLES[command]='fg=#89b4fa,bold'
FAST_HIGHLIGHT_STYLES[alias]='fg=#89b4fa,bold'
FAST_HIGHLIGHT_STYLES[builtin]='fg=#89b4fa,bold'
FAST_HIGHLIGHT_STYLES[subcommand]='fg=#89b4fa,bold'
FAST_HIGHLIGHT_STYLES[precommand]='fg=#89b4fa,bold'
FAST_HIGHLIGHT_STYLES[path]='fg=#cdd6f4'
FAST_HIGHLIGHT_STYLES[path-to-dir]='fg=#cdd6f4,underline'
FAST_HIGHLIGHT_STYLES[comment]='fg=#6c7086'
FAST_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#94e2d5'
FAST_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#94e2d5'
FAST_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#f9e2af'
FAST_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#f9e2af'
FAST_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#f9e2af'
FAST_HIGHLIGHT_STYLES[back-or-dollar-double-quoted-argument]='fg=#fab387'
FAST_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=#fab387'

# Keep history substring search highlights visible without the default magenta block.
typeset -g HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=#89b4fa,bold,underline'
typeset -g HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='fg=#f38ba8,bold,underline'
