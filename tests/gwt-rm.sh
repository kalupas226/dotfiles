#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/ui.sh"

GWT="${REPO_ROOT}/packages/bin/.local/bin/gwt"

fail() {
    warn "$*"
    exit 1
}

meta_file_for_task() {
    local repo_root="$1"
    local task="$2"

    printf '%s/.worktrees/.gwt/tasks/%s.tsv\n' \
        "$repo_root" \
        "$(printf '%s' "$task" | shasum | awk '{print $1}')"
}

assert_exists() {
    local path="$1"
    [[ -e "$path" ]] || fail "expected path to exist: $path"
}

assert_not_exists() {
    local path="$1"
    [[ ! -e "$path" ]] || fail "expected path to be absent: $path"
}

assert_branch_exists() {
    local repo_root="$1"
    local branch="$2"

    git -C "$repo_root" show-ref --verify --quiet "refs/heads/${branch}" ||
        fail "expected branch to exist: $branch"
}

setup_repo() {
    local repo_root="$1"
    local task="$2"
    local branch="$3"
    local dirty="${4:-0}"
    local worktree_path="${repo_root}/.worktrees/${task}"
    local metadata_file

    repo_root="$(cd "$repo_root" && pwd -P)"
    git init -q "$repo_root"
    git -C "$repo_root" config user.name "Test User"
    git -C "$repo_root" config user.email "test@example.com"

    printf 'base\n' >"${repo_root}/README.md"
    git -C "$repo_root" add README.md
    git -C "$repo_root" commit -qm "Initial commit"

    mkdir -p "${repo_root}/.worktrees/.gwt/tasks"
    git -C "$repo_root" worktree add -q -b "$branch" "$worktree_path"

    printf '%s\n' "$branch" >"${worktree_path}/feature.txt"
    git -C "$worktree_path" add feature.txt
    git -C "$worktree_path" commit -qm "Feature commit"

    if [[ "$dirty" == "1" ]]; then
        printf 'dirty\n' >>"${worktree_path}/feature.txt"
    fi

    metadata_file="$(meta_file_for_task "$repo_root" "$task")"
    printf '%s\t%s\t%s\t%s\t%s\n' \
        "$task" \
        "codex" \
        "$worktree_path" \
        "$branch" \
        "$repo_root" >"$metadata_file"
}

write_tmux_wrapper() {
    local wrapper_path="$1"

    cat >"$wrapper_path" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-}"
shift || true

case "$cmd" in
    has-session)
        exit 0
        ;;
    list-windows)
        printf '%%1 task-remove\n'
        ;;
    kill-window)
        exit 0
        ;;
    *)
        printf 'unexpected tmux command: %s\n' "$cmd" >&2
        exit 1
        ;;
esac
EOF
    chmod +x "$wrapper_path"
}

test_rm_removes_metadata_and_worktree_but_keeps_branch() {
    local repo_root
    local task="task-rm"
    local branch="task-rm"
    local metadata_file

    repo_root="$(mktemp -d /tmp/gwt-rm.XXXXXX)"
    repo_root="$(cd "$repo_root" && pwd -P)"

    setup_repo "$repo_root" "$task" "$branch"
    metadata_file="$(meta_file_for_task "$repo_root" "$task")"

    cd "$repo_root"
    "$GWT" rm "$task"

    assert_not_exists "$metadata_file"
    assert_not_exists "${repo_root}/.worktrees/${task}"
    assert_branch_exists "$repo_root" "$branch"
    rm -rf "$repo_root"
}

test_rm_rejects_dirty_worktree_without_force() {
    local repo_root
    local task="task-rm-dirty"
    local branch="task-rm-dirty"
    local metadata_file
    local output
    local rc

    repo_root="$(mktemp -d /tmp/gwt-rm-dirty.XXXXXX)"
    repo_root="$(cd "$repo_root" && pwd -P)"

    setup_repo "$repo_root" "$task" "$branch" 1
    metadata_file="$(meta_file_for_task "$repo_root" "$task")"

    set +e
    output="$(cd "$repo_root" && "$GWT" rm "$task" 2>&1)"
    rc=$?
    set -e

    [[ "$rc" -ne 0 ]] || fail "expected rm to fail for dirty worktree without --force"
    [[ "$output" == *"worktree has uncommitted changes"* ]] || fail "expected dirty-worktree error"
    [[ "$output" == *"gwt rm --force ${task}"* ]] || fail "expected recovery hint for --force"
    assert_exists "$metadata_file"
    assert_exists "${repo_root}/.worktrees/${task}"
    assert_branch_exists "$repo_root" "$branch"
    rm -rf "$repo_root"
}

test_rm_rejects_dirty_worktree_without_closing_tmux_window() {
    local repo_root
    local task="task-dirty-window"
    local branch="task-dirty-window"
    local wrapper_dir
    local tmux_log
    local output
    local rc

    repo_root="$(mktemp -d /tmp/gwt-rm-dirty-window.XXXXXX)"
    repo_root="$(cd "$repo_root" && pwd -P)"
    wrapper_dir="$(mktemp -d /tmp/gwt-rm-dirty-window-wrapper.XXXXXX)"
    wrapper_dir="$(cd "$wrapper_dir" && pwd -P)"
    tmux_log="$(mktemp /tmp/gwt-rm-dirty-window-log.XXXXXX)"

    setup_repo "$repo_root" "$task" "$branch" 1

    cat >"${wrapper_dir}/tmux" <<EOF
#!/usr/bin/env bash
set -euo pipefail

cmd="\${1:-}"
shift || true
printf '%s\n' "\$cmd" >>"${tmux_log}"

case "\$cmd" in
    has-session)
        exit 0
        ;;
    list-windows)
        printf '%%1 %s\n' "${task}"
        ;;
    kill-window)
        exit 0
        ;;
    *)
        exit 0
        ;;
esac
EOF
    chmod +x "${wrapper_dir}/tmux"

    set +e
    output="$(cd "$repo_root" && PATH="${wrapper_dir}:$PATH" "$GWT" rm "$task" 2>&1)"
    rc=$?
    set -e

    [[ "$rc" -ne 0 ]] || fail "expected rm to fail for dirty worktree without --force when tmux session exists"
    [[ "$output" == *"worktree has uncommitted changes"* ]] || fail "expected dirty-worktree error"
    [[ ! -s "$tmux_log" ]] || fail "expected rm to abort before calling tmux, got: $(cat "$tmux_log")"
    rm -rf "$repo_root" "$wrapper_dir" "$tmux_log"
}

test_rm_force_removes_dirty_worktree() {
    local repo_root
    local task="task-rm-force"
    local branch="task-rm-force"
    local metadata_file

    repo_root="$(mktemp -d /tmp/gwt-rm-force.XXXXXX)"
    repo_root="$(cd "$repo_root" && pwd -P)"

    setup_repo "$repo_root" "$task" "$branch" 1
    metadata_file="$(meta_file_for_task "$repo_root" "$task")"

    cd "$repo_root"
    "$GWT" rm --force "$task"

    assert_not_exists "$metadata_file"
    assert_not_exists "${repo_root}/.worktrees/${task}"
    assert_branch_exists "$repo_root" "$branch"
    rm -rf "$repo_root"
}

test_rm_cleans_tmux_window_when_session_exists() {
    local repo_root
    local task="task-remove"
    local branch="task-remove"
    local metadata_file
    local wrapper_dir

    repo_root="$(mktemp -d /tmp/gwt-rm-tmux.XXXXXX)"
    repo_root="$(cd "$repo_root" && pwd -P)"
    wrapper_dir="$(mktemp -d /tmp/gwt-rm-tmux-wrapper.XXXXXX)"
    wrapper_dir="$(cd "$wrapper_dir" && pwd -P)"

    setup_repo "$repo_root" "$task" "$branch"
    metadata_file="$(meta_file_for_task "$repo_root" "$task")"
    write_tmux_wrapper "${wrapper_dir}/tmux"

    cd "$repo_root"
    PATH="${wrapper_dir}:$PATH" "$GWT" rm "$task"

    assert_not_exists "$metadata_file"
    assert_not_exists "${repo_root}/.worktrees/${task}"
    assert_branch_exists "$repo_root" "$branch"
    rm -rf "$repo_root" "$wrapper_dir"
}

main() {
    step "Running gwt rm regression tests"
    test_rm_removes_metadata_and_worktree_but_keeps_branch
    ok "rm removes metadata and worktree while keeping the branch"
    test_rm_rejects_dirty_worktree_without_force
    ok "rm rejects dirty worktrees without --force"
    test_rm_rejects_dirty_worktree_without_closing_tmux_window
    ok "rm rejects dirty worktrees before touching tmux"
    test_rm_force_removes_dirty_worktree
    ok "rm --force removes dirty worktrees"
    test_rm_cleans_tmux_window_when_session_exists
    ok "rm cleans the tmux window when a session exists"
}

main "$@"
