# 起動時に tmux を起動
if [ $SHLVL = 1 ]; then
  tmux
fi

# Ctrl+Dでログアウトしてしまうことを防ぐ
setopt IGNOREEOF

# 日本語を使用
export LANG=ja_JP.UTF-8

# export PATH
export PATH="$HOME/bin:$PATH"
export PATH=$PATH:$HOME/.rbenv/bin
export PATH=$PATH:$HOME/.nodebrew/current/bin

# eval
eval "$(rbenv init -)"
eval "$(starship init zsh)"

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
alias v='vim'
alias vz='vim ~/.zshrc'
alias sz='source ~/.zshrc'
alias ls='exa --icons'
alias cat='bat'

# エイリアス(Git)
alias gl='git log'
alias gb='git branch'
alias gbd='git branch -d'
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gr='git restore'
alias gp='git pull origin'
alias gf='git fetch'
alias gswc='git switch --create'
alias gpsc='git push origin $(echo $(git rev-parse --abbrev-ref HEAD))'
alias gpsuc='git push -u origin $(echo $(git rev-parse --abbrev-ref HEAD))'

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

# function 
function gbdm() {
  git fetch --prune
  git branch --merged | egrep -v "\*|master|development" | xargs git branch -d
}

function gsw() {
  local branches branch
  branches=$(git branch -vv) &&
  branch=$(echo "$branches" | fzf +m) &&
  git switch $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

function gswr() {
    local branches branch
    branches=$(git branch --all | grep -v HEAD) &&
    branch=$(echo "$branches" |
             fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
    git switch $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

function gbdfzf() {
  local branches branch
  branches=$(git branch -vv) &&
  branch=$(echo "$branches" | fzf +m) &&
  git branch -D $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

function cdrepo() {
  local selected_dir=$(ghq list -p | fzf -q "$LBUFER" --preview='exa -l {}')
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N cdrepo
bindkey '^@' cdrepo

function cdrfzf() {
  local selected_dir=$(cdr -l | awk '{ print $2 }' | fzf --preview 'f() { sh -c "exa -l $1" }; f {}')
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N cdrfzf
bindkey '^o' cdrfzf

function fd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m --preview 'exa -l {}') &&
  cd "$dir"
}

function fdc() {
  DIR=`find * -maxdepth 1 -type d -print 2> /dev/null | fzf-tmux --preview 'exa -l {}'` \
  && cd "$DIR"
}

function fdp() {
  local declare dirs=()
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
  local DIR=$(get_parent_dirs $(myrealpath "${1:-$PWD}") | fzf-tmux --tac --preview 'exa -l {}')
  cd "$DIR"
}

# Haskell
[ -f "/Users/kenta.aikawa/.ghcup/env" ] && source "/Users/kenta.aikawa/.ghcup/env" # ghcup-env

# plantUML
export PLANTUML_LIMIT_SIZE=8192
