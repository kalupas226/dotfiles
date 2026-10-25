# Auto-start tmux before anything else so the outer shell skips the rest of
# the setup (skip in AI agent terminals)
if [ -z "$TMUX" ] && [ -z "$CLAUDE_CODE" ] && [ -z "$CODEX_SHELL" ] && command -v tmux >/dev/null 2>&1; then
  tmux attach-session -t home || tmux new-session -s home -n main
fi

ZSHDIR="${HOME}/.config/zsh"

source "$ZSHDIR/.options.zsh"
source "$ZSHDIR/.aliases.zsh"
source "$ZSHDIR/.functions.zsh"
source "$ZSHDIR/.completion.zsh"
source "$ZSHDIR/.integrations.zsh"
