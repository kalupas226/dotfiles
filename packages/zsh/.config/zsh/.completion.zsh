# Register local completion functions before initializing zsh completion.
fpath=("$ZSHDIR/completions" $fpath)

# Do the full (slow) scan at most once a day; otherwise trust the dump.
autoload -Uz compinit
_zcompdump_stale=("$HOME"/.zcompdump(N.mh+24))
if [[ ! -e "$HOME/.zcompdump" || ${#_zcompdump_stale} -gt 0 ]]; then
  compinit
else
  compinit -C
fi
unset _zcompdump_stale

setopt complete_aliases
zstyle ':completion:*:default' menu select=2
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
