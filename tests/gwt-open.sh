#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/ui.sh"

GWT="${REPO_ROOT}/packages/bin/.local/bin/gwt"
REAL_GIT="$(command -v git)"

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

setup_repo() {
    local repo_root="$1"
    local task="$2"
    local metadata_branch="$3"
    local actual_branch="$4"
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
    git -C "$repo_root" worktree add -q -b "$actual_branch" "$worktree_path"

    metadata_file="$(meta_file_for_task "$repo_root" "$task")"
    printf '%s\t%s\t%s\t%s\t%s\n' \
        "$task" \
        "codex" \
        "$worktree_path" \
        "$metadata_branch" \
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
        exit 1
        ;;
    new-session)
        exit 0
        ;;
    list-windows)
        printf '%%root\tproject@root\t\n'
        ;;
    new-window)
        printf '%%1\n'
        ;;
    list-panes)
        printf '%%2\n'
        ;;
    split-window)
        printf '%%3\n'
        ;;
    set-option|rename-window|select-layout|send-keys|select-pane|select-window|switch-client)
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

write_codex_wrapper() {
    local wrapper_path="$1"

    cat >"$wrapper_path" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$wrapper_path"
}

test_open_rejects_stale_branch_without_force() {
    local repo_root
    local task="task-open-stale"
    local output
    local rc

    repo_root="$(mktemp -d /tmp/gwt-open-stale.XXXXXX)"
    repo_root="$(cd "$repo_root" && pwd -P)"

    setup_repo "$repo_root" "$task" "expected-branch" "actual-branch"

    set +e
    output="$(cd "$repo_root" && "$GWT" open "$task" 2>&1)"
    rc=$?
    set -e

    [[ "$rc" -ne 0 ]] || fail "expected non-zero exit for stale metadata without --force"
    [[ "$output" == *"metadata is stale"* ]] || fail "expected stale metadata error"
    [[ "$output" == *"gwt open --force ${task}"* ]] || fail "expected recovery hint for --force"
    rm -rf "$repo_root"
}

test_open_force_allows_stale_branch_after_warning() {
    local repo_root
    local task="task-open-force"
    local wrapper_dir
    local output

    repo_root="$(mktemp -d /tmp/gwt-open-force.XXXXXX)"
    repo_root="$(cd "$repo_root" && pwd -P)"
    wrapper_dir="$(mktemp -d /tmp/gwt-open-wrapper.XXXXXX)"
    wrapper_dir="$(cd "$wrapper_dir" && pwd -P)"

    setup_repo "$repo_root" "$task" "expected-branch" "actual-branch"
    write_tmux_wrapper "${wrapper_dir}/tmux"
    write_codex_wrapper "${wrapper_dir}/codex"

    output="$(cd "$repo_root" && TMUX=1 PATH="${wrapper_dir}:$PATH" "$GWT" open --force "$task" 2>&1)"

    [[ "$output" == *"warning: task ${task} metadata is stale"* ]] || fail "expected stale metadata warning"
    [[ "$output" == *"continuing because --force was provided"* ]] || fail "expected force continuation warning"
    rm -rf "$repo_root" "$wrapper_dir"
}

main() {
    step "Running gwt open stale-metadata tests"
    test_open_rejects_stale_branch_without_force
    ok "open rejects stale branch metadata by default"
    test_open_force_allows_stale_branch_after_warning
    ok "open --force allows stale branch metadata after warning"
}

main "$@"
