# Shell basics
bindkey -e
setopt IGNOREEOF correct no_flow_control
autoload -Uz colors && colors

# Completion
autoload -Uz compinit && compinit
setopt complete_aliases
autoload -Uz select-word-style && select-word-style default
zstyle ':zle:*' word-chars "_-./;@"
zstyle ':zle:*' word-style unspecified
zstyle ':completion:*:default' menu select=2
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# History
setopt share_history histignorealldups
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^n" history-beginning-search-forward-end

# Directory navigation
setopt auto_cd auto_pushd pushd_ignore_dups
cdpath=(~)
autoload -Uz add-zsh-hook chpwd_recent_dirs cdr
add-zsh-hook chpwd chpwd_recent_dirs
zstyle ":chpwd:*" recent-dirs-default true
