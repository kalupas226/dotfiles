# Tool initialization
eval "$(sheldon source)"

# Initialize completion after sheldon so plugin completions are in fpath.
# Do the full (slow) scan at most once a day; otherwise trust the dump.
autoload -Uz compinit
_zcompdump_stale=("$HOME"/.zcompdump(N.mh+24))
if [[ ! -e "$HOME/.zcompdump" || ${#_zcompdump_stale} -gt 0 ]]; then
  compinit
else
  compinit -C
fi
unset _zcompdump_stale

eval "$(starship init zsh)"
eval "$(mise activate zsh)"
eval "$(zoxide init zsh)"
