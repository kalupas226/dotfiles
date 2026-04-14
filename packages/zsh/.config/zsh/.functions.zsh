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
function gbdm() {
  local default_branch=""
  local base_ref=""
  local current_branch=""
  local -a branches

  git fetch --prune

  default_branch="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  default_branch="${default_branch#origin/}"

  if [[ -n "$default_branch" ]] && git rev-parse --verify "refs/remotes/origin/${default_branch}" >/dev/null 2>&1; then
    base_ref="refs/remotes/origin/${default_branch}"
  elif git rev-parse --verify "refs/heads/main" >/dev/null 2>&1; then
    default_branch="main"
    base_ref="refs/heads/main"
  elif git rev-parse --verify "refs/remotes/origin/main" >/dev/null 2>&1; then
    default_branch="main"
    base_ref="refs/remotes/origin/main"
  elif git rev-parse --verify "refs/heads/master" >/dev/null 2>&1; then
    default_branch="master"
    base_ref="refs/heads/master"
  elif git rev-parse --verify "refs/remotes/origin/master" >/dev/null 2>&1; then
    default_branch="master"
    base_ref="refs/remotes/origin/master"
  else
    printf 'gbdm: could not determine default branch\n' >&2
    return 1
  fi

  current_branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
  branches=("${(@f)$(git for-each-ref --format='%(refname:short)' --merged "$base_ref" refs/heads | grep -E -v "^(${default_branch}|main|master|development)$" || true)}")

  if [[ -n "$current_branch" ]]; then
    branches=("${(@)branches:#$current_branch}")
  fi

  (( ${#branches[@]} )) || return 0
  git branch -d -- "${branches[@]}"
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
