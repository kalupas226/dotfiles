# Auto-start tmux before anything else so the outer shell skips the rest of
# the setup (skip in AI agent / VS Code terminals)
if [ -z "$TMUX" ] && [ -z "$CLAUDE_CODE" ] && [ -z "$CODEX_SHELL" ] && [ "$TERM_PROGRAM" != "vscode" ] && command -v tmux >/dev/null 2>&1; then
  tmux attach-session -t home || tmux new-session -s home -n main
fi

ZSHDIR="${HOME}/.config/zsh"

source "$ZSHDIR/.options.zsh"
source "$ZSHDIR/.aliases.zsh"
source "$ZSHDIR/.fzf.zsh"
source "$ZSHDIR/.functions.zsh"
source "$ZSHDIR/.plugins.zsh"
source "$ZSHDIR/.theme.zsh"
