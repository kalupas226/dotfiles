# Shell basics
bindkey -v
setopt correct no_flow_control
bindkey -M viins "^D" delete-char-or-list
bindkey -M viins "^?" backward-delete-char
bindkey -M viins "^H" backward-delete-char
autoload -Uz colors && colors
autoload -Uz select-word-style && select-word-style default
zstyle ':zle:*' word-chars "_-./;@"
zstyle ':zle:*' word-style unspecified

# History
setopt share_history histignorealldups
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Directory navigation
setopt auto_cd auto_pushd pushd_ignore_dups
cdpath=(~)
autoload -Uz add-zsh-hook chpwd_recent_dirs cdr
add-zsh-hook chpwd chpwd_recent_dirs
zstyle ":chpwd:*" recent-dirs-default true
