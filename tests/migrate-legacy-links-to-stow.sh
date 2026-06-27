#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/ui.sh"

MIGRATOR="${REPO_ROOT}/scripts/migrate-legacy-links-to-stow.sh"

fail() {
    warn "$*"
    exit 1
}

test_removes_only_legacy_repo_symlinks() {
    local tmp_home
    local other_target
    local dry_run_output

    tmp_home="$(mktemp -d /tmp/migrate-legacy-links-home.XXXXXX)"
    other_target="$(mktemp /tmp/migrate-legacy-links-other.XXXXXX)"

    mkdir -p "${tmp_home}/.config/nvim" "${tmp_home}/.config/git"
    ln -s "${REPO_ROOT}/packages/zsh/.zshrc" "${tmp_home}/.zshrc"
    ln -s "$other_target" "${tmp_home}/.config/nvim/init.lua"
    printf 'regular\n' >"${tmp_home}/.config/git/config"

    dry_run_output="$(HOME="$tmp_home" bash "$MIGRATOR" --dry-run)"
    [[ "$dry_run_output" == *"${tmp_home}/.zshrc"* ]] ||
        fail "expected dry-run to report the legacy symlink"
    [[ -L "${tmp_home}/.zshrc" ]] ||
        fail "expected dry-run not to remove legacy symlink"

    HOME="$tmp_home" bash "$MIGRATOR" >/dev/null

    [[ ! -e "${tmp_home}/.zshrc" ]] ||
        fail "expected migration to remove the legacy symlink"
    [[ -L "${tmp_home}/.config/nvim/init.lua" ]] ||
        fail "expected migration to leave unrelated symlinks untouched"
    [[ -f "${tmp_home}/.config/git/config" ]] ||
        fail "expected migration to leave regular files untouched"

    rm -rf "$tmp_home" "$other_target"
}

main() {
    step "Running legacy link migration tests"
    test_removes_only_legacy_repo_symlinks
    ok "removes only old repo-pointing symlinks"
}

main "$@"
