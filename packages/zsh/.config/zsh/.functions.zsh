# Lazygit wrapper (cd into new dir after exit)
function lg() {
  local newdir_file=~/.lazygit/newdir
  LAZYGIT_NEW_DIR_FILE="$newdir_file" lazygit "$@"
  if [[ -f "$newdir_file" ]]; then
    cd "$(cat "$newdir_file")"
    rm -f "$newdir_file"
  fi
}

# Git: repository navigation
function groot() {
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    printf 'groot: not inside a git worktree\n' >&2
    return 1
  }
  cd -- "$root"
}

# Git: branch helpers
function gbrm() {
  git rev-parse --git-dir >/dev/null 2>&1 || {
    printf 'gbrm: not inside a git repository\n' >&2
    return 1
  }

  local default_branch=""
  local current_branch=""
  local -a branches

  default_branch="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  default_branch="${default_branch#origin/}"
  current_branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
  branches=("${(@f)$(git for-each-ref --format='%(refname:short)' refs/heads)}")

  [[ -n "$default_branch" ]] && branches=("${(@)branches:#$default_branch}")
  [[ -n "$current_branch" ]] && branches=("${(@)branches:#$current_branch}")
  branches=("${(@)branches:#main}")
  branches=("${(@)branches:#master}")
  branches=("${(@)branches:#development}")

  if (( ! ${#branches[@]} )); then
    printf 'gbrm: no local branches to remove\n' >&2
    return 0
  fi

  local selected
  selected="$(printf '%s\n' "${branches[@]}" |
             fzf --multi --preview 'git log --oneline -15 {}')" || return

  branches=("${(@f)selected}")
  (( ${#branches[@]} )) || return 0

  printf 'Remove selected branch(es)?\n'
  printf '  %s\n' "${branches[@]}"
  printf 'Continue? [y/N] '

  local answer
  read -r answer
  [[ "$answer" == "y" || "$answer" == "Y" ]] || return 1

  git branch -d -- "${branches[@]}"
}

function gbclean() {
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
    printf 'gbclean: could not determine default branch\n' >&2
    return 1
  fi

  current_branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
  branches=("${(@f)$(git for-each-ref --format='%(refname:short)' --merged "$base_ref" refs/heads | grep -E -v "^(${default_branch}|main|master|development)$" || true)}")

  if [[ -n "$current_branch" ]]; then
    branches=("${(@)branches:#$current_branch}")
  fi

  if (( ! ${#branches[@]} )); then
    printf 'gbclean: no merged local branches\n'
    return 0
  fi

  printf 'Remove merged branch(es)?\n'
  printf '  %s\n' "${branches[@]}"
  printf 'Continue? [y/N] '

  local answer
  read -r answer
  [[ "$answer" == "y" || "$answer" == "Y" ]] || return 1

  git branch -d -- "${branches[@]}"
}

# Git: switch helpers
function gswl() {
  local branch
  branch=$(git for-each-ref --format='%(refname:short)' refs/heads |
           fzf +m --preview 'git log --oneline -15 {}') || return
  [[ -n "$branch" ]] && git switch "$branch"
}

function gswr() {
  local branch
  branch=$(git branch --all --format='%(refname:short)' |
           grep -v HEAD |
           fzf --preview 'git log --oneline -15 {1}') || return
  git switch "${branch#origin/}"
}

# Git: worktree helpers
function gwtc() {
  git rev-parse --git-dir >/dev/null 2>&1 || {
    printf 'gwtc: not inside a git repository\n' >&2
    return 1
  }

  local dir
  dir="$(git worktree list --porcelain |
         awk '/^worktree / { sub(/^worktree /, ""); print }' |
         fzf --preview 'git -C {} status --short --branch 2>/dev/null')" || return

  [[ -n "$dir" ]] && cd -- "$dir"
}

function gwtrm() {
  local current
  current="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    printf 'gwtrm: not inside a git worktree\n' >&2
    return 1
  }

  local candidates
  candidates="$(git worktree list --porcelain |
                awk '/^worktree / { sub(/^worktree /, ""); print }' |
                grep -v -F -x "$current" || true)"

  if [[ -z "$candidates" ]]; then
    printf 'gwtrm: no other worktrees\n' >&2
    return 0
  fi

  local selected
  selected="$(printf '%s\n' "$candidates" |
             fzf --multi --preview 'git -C {} status --short --branch 2>/dev/null')" || return

  local -a dirs
  dirs=("${(@f)selected}")
  (( ${#dirs[@]} )) || return 0

  printf 'Remove selected worktree(s)?\n'
  printf '  %s\n' "${dirs[@]}"
  printf 'Continue? [y/N] '

  local answer
  read -r answer
  [[ "$answer" == "y" || "$answer" == "Y" ]] || return 1

  local dir
  for dir in "${dirs[@]}"; do
    git worktree remove -- "$dir" || return
  done
}

function gwtp() {
  git rev-parse --git-dir >/dev/null 2>&1 || {
    printf 'gwtp: not inside a git repository\n' >&2
    return 1
  }

  local output
  output="$(git worktree prune --dry-run --verbose 2>&1)" || return
  if [[ -z "$output" ]]; then
    printf 'gwtp: no stale worktree entries\n'
    return 0
  fi

  printf '%s\n' "$output"
  printf 'Prune stale worktree entries? [y/N] '

  local answer
  read -r answer
  [[ "$answer" == "y" || "$answer" == "Y" ]] || return 1

  git worktree prune --verbose
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
