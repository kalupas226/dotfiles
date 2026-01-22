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

# Tig aliases
alias t='tig'

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
bindkey '^r' history-incremental-pattern-search-backward
bindkey '^s' history-incremental-pattern-search-forward

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
  branch=$(git for-each-ref --format='%(refname:short)' refs/heads | fzf +m) || return
  [[ -n "$branch" ]] && git switch "$branch"
}

function gswr() {
  # Switch to remote branch using fzf
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
  branch=$(echo "$branches" |
           fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git switch $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

function gbd() {
  # Force delete branches using fzf (supports multiple selection)
  local -a branches
  branches=("${(@f)$(git for-each-ref --format='%(refname:short)' refs/heads | fzf -m)}") || return
  (( ${#branches[@]} )) && git branch -D -- "${branches[@]}"
}

# Directory navigation with fzf
function cdrepo() {
  # Navigate to ghq managed repository using fzf (Ctrl+@)
  local selected_dir=$(ghq list -p | fzf -q "$LBUFFER" --preview='eza -l {}')
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N cdrepo
bindkey '^@' cdrepo

function fd() {
  # Find and navigate to directory using fzf
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m --preview 'eza -l {}') &&
  cd "$dir"
}

function fdc() {
  # Find and navigate to child directory using fzf
  DIR=`find * -maxdepth 1 -type d -print 2> /dev/null | fzf-tmux --preview 'eza -l {}'` \
  && cd "$DIR"
}

function fdp() {
  # Find and navigate to parent directory using fzf
  local -a dirs=()
  get_parent_dirs() {
    if [[ -d "${1}" ]]; then dirs+=("$1"); else return; fi
    if [[ "${1}" == '/' ]]; then
      for _dir in "${dirs[@]}"; do echo $_dir; done
    else
      get_parent_dirs $(dirname "$1")
    fi
  }
  myrealpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
  }
  local DIR=$(get_parent_dirs $(myrealpath "${1:-$PWD}") | fzf-tmux --tac --preview 'eza -l {}')
  cd "$DIR"
}

# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------

# Auto-start tmux (except for SSH connections)
if [ -z "$TMUX" ] && [ -z "$SSH_CONNECTION" ] && command -v tmux >/dev/null 2>&1; then
  tmux attach-session -t main || tmux new-session -s main
fi

# Initialize tools
eval "$(sheldon source)"
eval "$(starship init zsh)"
eval "$(mise activate zsh)"
eval "$(zoxide init zsh)"
