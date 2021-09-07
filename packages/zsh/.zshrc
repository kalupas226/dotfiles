# 起動時に tmux を起動
if [ $SHLVL = 1 ]; then
  tmux
fi

# Ctrl+Dでログアウトしてしまうことを防ぐ
setopt IGNOREEOF

# terminal の操作を vi keybind にする
set -o vi

# 日本語を使用
export LANG=ja_JP.UTF-8

# export PATH
export PATH="$HOME/bin:$PATH"

# 色を使用
autoload -Uz colors
colors

# 補完
autoload -Uz compinit
compinit

# history
setopt share_history
setopt histignorealldups
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
# historyに日付を表示
alias h='fc -lt '%F %T' 1'

# cdコマンドを省略して、ディレクトリ名のみの入力で移動
setopt auto_cd
# 自動でpushdを実行
setopt auto_pushd
# pushdから重複を削除
setopt pushd_ignore_dups

# コマンドミスを修正
setopt correct

# グローバルエイリアス
alias -g L='| less'
alias -g H='| head'
alias -g G='| grep'
alias -g GI='| grep -ri'

# エイリアス
alias lst='ls -ltr --color=auto'
alias l='ls -ltr --color=auto'
alias la='ls -la --color=auto'
alias ll='ls -l --color=auto'
alias so='source'
alias v='vim'
alias vi='vim'
alias vz='vim ~/.zshrc'

# エイリアス(Git)
alias gl='git log'
alias gb='git branch'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gsw='git switch'
alias gswc='git switch -c'
alias gr='git restore'
alias gps='git push'
alias gpsu='git push -u origin'
alias gp='git pull origin'
alias gpset='git push --set-upstream origin'
alias -g B='`git branch -a | peco --prompt "GIT BRANCH>" | head -n 1 | sed -e "s/^\*\s*//g"`'

# エイリアス(tig)
alias t='tig'
alias tr='tig refs'
alias ts='tig status'

# どこからでも参照できるディレクトリパス
cdpath=(~)

# 区切り文字の設定
autoload -Uz select-word-style
select-word-style default
zstyle ':zle:*' word-chars "_-./;@"
zstyle ':zle:*' word-style unspecified

# Ctrl+sのロック, Ctrl+qのロック解除を無効にする
setopt no_flow_control

# 補完後、メニュー選択モードになり左右キーで移動が出来る
zstyle ':completion:*:default' menu select=2

# 補完で大文字にもマッチ
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Ctrl+rでヒストリーのインクリメンタルサーチ、Ctrl+sで逆順
bindkey '^r' history-incremental-pattern-search-backward
bindkey '^s' history-incremental-pattern-search-forward

# コマンドを途中まで入力後、historyから絞り込み
# 例 ls まで打ってCtrl+pでlsコマンドをさかのぼる、Ctrl+bで逆順
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^n" history-beginning-search-forward-end

# cdrコマンドを有効 ログアウトしても有効なディレクトリ履歴
# cdr タブでリストを表示
autoload -Uz add-zsh-hook
autoload -Uz chpwd_recent_dirs cdr
add-zsh-hook chpwd chpwd_recent_dirs
# cdrコマンドで履歴にないディレクトリにも移動可能に
zstyle ":chpwd:*" recent-dirs-default true

# peco
function peco-src() {
  local selected_dir=$(ghq list -p | peco --query "$LBUFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N peco-src
bindkey '^g' peco-src

function peco-cdr() {
  local selected_dir=$(cdr -l | awk '{ print $2 }' | peco)
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N peco-cdr
bindkey '^o' peco-cdr

# rbenv
export PATH=~/.rbenv/bin:$PATH
eval "$(rbenv init -)"

# nodebrew
export PATH=$PATH:$HOME/.nodebrew/current/bin

# starship
eval "$(starship init zsh)"

# Haskell
[ -f "/Users/kenta.aikawa/.ghcup/env" ] && source "/Users/kenta.aikawa/.ghcup/env" # ghcup-env

# plantUML
export PLANTUML_LIMIT_SIZE=8192
