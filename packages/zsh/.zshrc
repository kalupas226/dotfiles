# =============================================================================
# ZSH CONFIGURATION
# =============================================================================

# -----------------------------------------------------------------------------
# Basic Settings
# -----------------------------------------------------------------------------
bindkey -e
setopt IGNOREEOF  # Prevent logout with Ctrl+D
setopt correct    # Command correction

# Colors
autoload -Uz colors && colors

# Completion
autoload -Uz compinit && compinit
setopt complete_aliases

# -----------------------------------------------------------------------------
# History Configuration
# -----------------------------------------------------------------------------
setopt share_history
setopt histignorealldups
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# -----------------------------------------------------------------------------
# Directory Navigation
# -----------------------------------------------------------------------------
setopt auto_cd           # Change directory without cd command
setopt auto_pushd        # Automatically pushd
setopt pushd_ignore_dups # Remove duplicates from pushd
cdpath=(~)               # Global directory paths

# Directory history (cdr command)
autoload -Uz add-zsh-hook
autoload -Uz chpwd_recent_dirs cdr
add-zsh-hook chpwd chpwd_recent_dirs
zstyle ":chpwd:*" recent-dirs-default true

# -----------------------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------------------

# Aliases
alias ls='eza --icons'
alias cat='bat'
alias vim='nvim'
alias gl='git log'
alias gb='git branch'
alias gs='git status'
alias gr='git restore'
alias gd='git diff'
alias gpl='git pull origin'
alias gfc='git fetch'
alias gswc='git switch --create'
alias gpsc='git push origin $(git rev-parse --abbrev-ref HEAD)'
alias gpsuc='git push -u origin $(git rev-parse --abbrev-ref HEAD)'

# -----------------------------------------------------------------------------
# fzf Configuration
# -----------------------------------------------------------------------------
export FZF_DEFAULT_OPTS='
  --height=60%
  --layout=reverse
  --border
  --info=inline
  --bind=ctrl-d:half-page-down,ctrl-u:half-page-up
'

# fzf shell integration (Ctrl+R history search, Ctrl+T file finder, Alt+C cd)
source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
source /opt/homebrew/opt/fzf/shell/completion.zsh

function lg() {
  local newdir_file=~/.lazygit/newdir
  LAZYGIT_NEW_DIR_FILE="$newdir_file" lazygit "$@"
  if [[ -f "$newdir_file" ]]; then
    cd "$(cat "$newdir_file")"
    rm -f "$newdir_file"
  fi
}

# -----------------------------------------------------------------------------
# Completion & Key Bindings
# -----------------------------------------------------------------------------

# Word selection
autoload -Uz select-word-style
select-word-style default
zstyle ':zle:*' word-chars "_-./;@"
zstyle ':zle:*' word-style unspecified

# Completion settings
zstyle ':completion:*:default' menu select=2
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Key bindings
setopt no_flow_control  # Disable Ctrl+s/Ctrl+q flow control

# History search with partial input (original behavior)
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^n" history-beginning-search-forward-end

# Zoxide interactive selection
function zoxide_interactive() {
  local dir=$(zoxide query -i)
  if [[ -n "$dir" ]]; then
    cd "$dir"
  fi
  zle reset-prompt
}
zle -N zoxide_interactive
bindkey "^z" zoxide_interactive

# -----------------------------------------------------------------------------
# Custom Functions
# -----------------------------------------------------------------------------

# Git branch management
function gbdmerged() {
  # Delete merged branches (exclude master/development/current)
  git fetch --prune
  git branch --merged | egrep -v "\*|master|main|development" | xargs git branch -d
}

function gswl() {
  # Switch to local branch using fzf
  local branch
  branch=$(git for-each-ref --format='%(refname:short)' refs/heads |
           fzf +m --preview 'git log --oneline -15 {}') || return
  [[ -n "$branch" ]] && git switch "$branch"
}

function gswr() {
  # Switch to remote branch using fzf
  local branch
  branch=$(git branch --all --format='%(refname:short)' |
           grep -v HEAD |
           fzf --preview 'git log --oneline -15 {1}') || return
  git switch "${branch#origin/}"
}

function gbd() {
  # Force delete branches using fzf (supports multiple selection)
  local -a branches
  branches=("${(@f)$(git for-each-ref --format='%(refname:short)' refs/heads | fzf -m)}") || return
  (( ${#branches[@]} )) && git branch -D -- "${branches[@]}"
}

function glog() {
  # Browse git log with fzf, preview shows commit diff
  git log --oneline --color=always |
    fzf --ansi --no-sort \
        --preview 'git show --color=always {1}' \
        --preview-window=right:60% \
        --bind 'enter:execute(git show --color=always {1} | less -R)'
}

function gstash() {
  # Browse stashes with fzf, preview shows stash diff, enter applies
  local stash
  stash=$(git stash list |
          fzf --preview 'git stash show -p --color=always $(echo {} | cut -d: -f1)' \
              --preview-window=right:60%) || return
  local stash_ref=$(echo "$stash" | cut -d: -f1)
  echo "Apply $stash_ref? [y/N] "
  read -q && git stash apply "$stash_ref"
}

function gadd() {
  # Interactive git add with fzf multi-select and diff preview
  local -a files
  files=("${(@f)$(git diff --name-only |
         fzf -m --preview 'git diff --color=always -- {}')}") || return
  (( ${#files[@]} )) && git add -- "${files[@]}" && git status --short
}

# Directory navigation with fzf
function cdrepo() {
  # Navigate to ghq managed repository using fzf (Ctrl+@)
  local selected_dir=$(ghq list -p | fzf -q "$LBUFFER" --preview='eza -l --icons --color=always {}')
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N cdrepo
bindkey '^@' cdrepo


# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------

# Auto-start tmux (except in AI agent / VS Code terminals)
if [ -z "$TMUX" ] && [ -z "$CLAUDE_CODE" ] && [ -z "$CODEX" ] && [ "$TERM_PROGRAM" != "vscode" ] && command -v tmux >/dev/null 2>&1; then
  tmux attach-session -t main || tmux new-session -s main
fi

# Initialize tools
eval "$(sheldon source)"
eval "$(starship init zsh)"
eval "$(mise activate zsh)"
eval "$(zoxide init zsh)"
