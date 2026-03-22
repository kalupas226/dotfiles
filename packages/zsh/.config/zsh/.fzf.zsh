export FZF_DEFAULT_OPTS='
  --height=60%
  --layout=reverse
  --border
  --info=inline
  --bind=ctrl-d:half-page-down,ctrl-u:half-page-up
'

# Shell integration (Ctrl+R: history, Ctrl+T: files, Alt+C: cd)
source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
source /opt/homebrew/opt/fzf/shell/completion.zsh
