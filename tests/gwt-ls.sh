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

test_ls_fails_cleanly_outside_git_repo() {
    local temp_dir
    local output
    local rc

    temp_dir="$(mktemp -d /tmp/gwt-ls-non-git.XXXXXX)"
    temp_dir="$(cd "$temp_dir" && pwd -P)"

    set +e
    output="$(cd "$temp_dir" && "$GWT" ls 2>&1)"
    rc=$?
    set -e

    [[ "$rc" -ne 0 ]] || fail "expected non-zero exit outside a git repository"
    [[ "$output" == "gwt: not inside a git repository" ]] || fail "expected a single clean error message, got: $output"

    rm -rf "$temp_dir"
}

main() {
    step "Running gwt ls non-repository test"
    test_ls_fails_cleanly_outside_git_repo
    ok "ls fails cleanly outside a git repository"
}

main "$@"
