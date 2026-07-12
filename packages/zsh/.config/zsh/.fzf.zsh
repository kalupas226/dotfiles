export FZF_DEFAULT_OPTS='
  --height=60%
  --layout=reverse
  --border
  --info=inline
  --bind=ctrl-d:half-page-down,ctrl-u:half-page-up
'

# Shell integration (Ctrl+R: history, Ctrl+T: files, Alt+C: cd)
if command -v brew >/dev/null 2>&1; then
  fzf_prefix="$(brew --prefix fzf 2>/dev/null)"
  if [ -n "$fzf_prefix" ]; then
    [ -r "$fzf_prefix/shell/key-bindings.zsh" ] && source "$fzf_prefix/shell/key-bindings.zsh"
    [ -r "$fzf_prefix/shell/completion.zsh" ] && source "$fzf_prefix/shell/completion.zsh"
  fi
  unset fzf_prefix
fi
