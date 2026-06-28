#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/ui.sh"

DOCTOR="${REPO_ROOT}/scripts/doctor.sh"

fail() {
    warn "$*"
    exit 1
}

test_reports_broken_dotfiles_package_symlinks() {
    local tmp_home
    local scan_root
    local output

    tmp_home="$(mktemp -d /tmp/dotfiles-doctor-home.XXXXXX)"
    scan_root="${tmp_home}/.local/bin"
    mkdir -p "$scan_root"

    ln -s "${REPO_ROOT}/packages/bin/.local/bin/missing-helper" "${scan_root}/old-helper"
    ln -s "/tmp/not-dotfiles/missing-helper" "${scan_root}/other-helper"

    if output="$(HOME="$tmp_home" DOTFILES_DOCTOR_SCAN_ROOTS="$scan_root" bash "$DOCTOR" 2>&1)"; then
        fail "expected doctor to report broken dotfiles symlinks"
    fi

    [[ "$output" == *"${scan_root}/old-helper -> ${REPO_ROOT}/packages/bin/.local/bin/missing-helper"* ]] ||
        fail "expected doctor to report the broken dotfiles package symlink"
    [[ "$output" != *"other-helper"* ]] ||
        fail "expected doctor to ignore unrelated broken symlinks"

    rm -rf "$tmp_home"
}

test_succeeds_without_broken_dotfiles_package_symlinks() {
    local tmp_home
    local scan_root

    tmp_home="$(mktemp -d /tmp/dotfiles-doctor-clean-home.XXXXXX)"
    scan_root="${tmp_home}/.local/bin"
    mkdir -p "$scan_root"
    ln -s "/tmp/not-dotfiles/missing-helper" "${scan_root}/other-helper"

    HOME="$tmp_home" DOTFILES_DOCTOR_SCAN_ROOTS="$scan_root" bash "$DOCTOR" >/dev/null ||
        fail "expected doctor to succeed when only unrelated broken symlinks exist"

    rm -rf "$tmp_home"
}

main() {
    step "Running dotfiles doctor tests"
    test_reports_broken_dotfiles_package_symlinks
    ok "reports broken dotfiles package symlinks"
    test_succeeds_without_broken_dotfiles_package_symlinks
    ok "succeeds without broken dotfiles package symlinks"
}

main "$@"
