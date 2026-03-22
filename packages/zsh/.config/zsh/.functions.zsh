# Lazygit wrapper (cd into new dir after exit)
function lg() {
  local newdir_file=~/.lazygit/newdir
  LAZYGIT_NEW_DIR_FILE="$newdir_file" lazygit "$@"
  if [[ -f "$newdir_file" ]]; then
    cd "$(cat "$newdir_file")"
    rm -f "$newdir_file"
  fi
}

# Git: delete merged branches
function gbdmerged() {
  git fetch --prune
  git branch --merged | egrep -v "\*|master|main|development" | xargs git branch -d
}

# Git: switch to local branch (fzf)
function gswl() {
  local branch
  branch=$(git for-each-ref --format='%(refname:short)' refs/heads |
           fzf +m --preview 'git log --oneline -15 {}') || return
  [[ -n "$branch" ]] && git switch "$branch"
}

# Git: switch to remote branch (fzf)
function gswr() {
  local branch
  branch=$(git branch --all --format='%(refname:short)' |
           grep -v HEAD |
           fzf --preview 'git log --oneline -15 {1}') || return
  git switch "${branch#origin/}"
}

# Git: force delete branches (fzf multi-select)
function gbd() {
  local -a branches
  branches=("${(@f)$(git for-each-ref --format='%(refname:short)' refs/heads | fzf -m)}") || return
  (( ${#branches[@]} )) && git branch -D -- "${branches[@]}"
}

# Git: browse log (fzf)
function glog() {
  git log --oneline --color=always |
    fzf --ansi --no-sort \
        --preview 'git show --color=always {1}' \
        --preview-window=right:60% \
        --bind 'enter:execute(git show --color=always {1} | less -R)'
}

# Git: browse and apply stash (fzf)
function gstash() {
  local stash
  stash=$(git stash list |
          fzf --preview 'git stash show -p --color=always $(echo {} | cut -d: -f1)' \
              --preview-window=right:60%) || return
  local stash_ref=$(echo "$stash" | cut -d: -f1)
  echo "Apply $stash_ref? [y/N] "
  read -q && git stash apply "$stash_ref"
}

# Git: interactive add (fzf multi-select)
function gadd() {
  local -a files
  files=("${(@f)$(git diff --name-only |
         fzf -m --preview 'git diff --color=always -- {}')}") || return
  (( ${#files[@]} )) && git add -- "${files[@]}" && git status --short
}

# Zoxide interactive selection (Ctrl+z)
function zoxide_interactive() {
  local dir=$(zoxide query -i)
  if [[ -n "$dir" ]]; then
    cd "$dir"
  fi
  zle reset-prompt
}
zle -N zoxide_interactive
bindkey "^z" zoxide_interactive

# Navigate to ghq repository (Ctrl+@)
function cdrepo() {
  local selected_dir=$(ghq list -p | fzf -q "$LBUFFER" --preview='eza -l --icons --color=always {}')
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N cdrepo
bindkey '^@' cdrepo
