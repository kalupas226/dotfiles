# zsh integration for external binaries. The binaries themselves are
# managed by Brewfile / mise; this file only wires them into the shell.

# fzf
export FZF_DEFAULT_OPTS='
  --height=60%
  --layout=reverse
  --border
  --info=inline
  --bind=ctrl-d:half-page-down,ctrl-u:half-page-up
'
# Shell integration (Ctrl+R: history, Ctrl+T: files, Alt+C: cd)
fzf_base="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf"
[ -r "$fzf_base/shell/key-bindings.zsh" ] && source "$fzf_base/shell/key-bindings.zsh"
[ -r "$fzf_base/shell/completion.zsh" ] && source "$fzf_base/shell/completion.zsh"
unset fzf_base

eval "$(starship init zsh)"
eval "$(mise activate zsh)"
eval "$(zoxide init zsh)"
