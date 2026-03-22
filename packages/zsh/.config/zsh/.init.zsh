# Auto-start tmux (skip in AI agent / VS Code terminals)
if [ -z "$TMUX" ] && [ -z "$CLAUDE_CODE" ] && [ -z "$CODEX" ] && [ "$TERM_PROGRAM" != "vscode" ] && command -v tmux >/dev/null 2>&1; then
  tmux attach-session -t main || tmux new-session -s main
fi

# Tool initialization
eval "$(sheldon source)"
eval "$(starship init zsh)"
eval "$(mise activate zsh)"
eval "$(zoxide init zsh)"
