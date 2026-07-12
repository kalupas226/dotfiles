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
    local packages_dir
    local scan_root
    local output

    tmp_home="$(mktemp -d /tmp/dotfiles-doctor-home.XXXXXX)"
    packages_dir="${tmp_home}/packages"
    scan_root="${tmp_home}/.local/bin"
    mkdir -p "$packages_dir" "$scan_root"

    ln -s "${REPO_ROOT}/packages/bin/.local/bin/missing-helper" "${scan_root}/old-helper"
    ln -s "/tmp/not-dotfiles/missing-helper" "${scan_root}/other-helper"

    if output="$(HOME="$tmp_home" DOTFILES_DOCTOR_PACKAGES_DIR="$packages_dir" DOTFILES_DOCTOR_SCAN_ROOTS="$scan_root" bash "$DOCTOR" 2>&1)"; then
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
    local packages_dir
    local scan_root

    tmp_home="$(mktemp -d /tmp/dotfiles-doctor-clean-home.XXXXXX)"
    packages_dir="${tmp_home}/packages"
    scan_root="${tmp_home}/.local/bin"
    mkdir -p "$packages_dir" "$scan_root"
    ln -s "/tmp/not-dotfiles/missing-helper" "${scan_root}/other-helper"

    HOME="$tmp_home" DOTFILES_DOCTOR_PACKAGES_DIR="$packages_dir" DOTFILES_DOCTOR_SCAN_ROOTS="$scan_root" bash "$DOCTOR" >/dev/null ||
        fail "expected doctor to succeed when only unrelated broken symlinks exist"

    rm -rf "$tmp_home"
}

test_reports_managed_dotfile_link_issues() {
    local tmpdir
    local tmp_home
    local packages_dir
    local scan_root
    local output

    tmpdir="$(mktemp -d /tmp/dotfiles-doctor-managed.XXXXXX)"
    tmp_home="${tmpdir}/home"
    packages_dir="${tmpdir}/packages"
    scan_root="${tmp_home}/.config"

    mkdir -p \
        "${packages_dir}/example/.config/example" \
        "${tmp_home}/.config/example"
    touch \
        "${packages_dir}/example/.config/example/good" \
        "${packages_dir}/example/.config/example/missing" \
        "${packages_dir}/example/.config/example/regular" \
        "${packages_dir}/example/.config/example/wrong" \
        "${tmpdir}/other-target"
    ln -s "${packages_dir}/example/.config/example/good" "${tmp_home}/.config/example/good"
    touch "${tmp_home}/.config/example/regular"
    ln -s "${tmpdir}/other-target" "${tmp_home}/.config/example/wrong"

    if output="$(HOME="$tmp_home" DOTFILES_DOCTOR_PACKAGES_DIR="$packages_dir" DOTFILES_DOCTOR_SCAN_ROOTS="$scan_root" bash "$DOCTOR" 2>&1)"; then
        fail "expected doctor to report managed dotfile link issues"
    fi

    [[ "$output" == *"missing: ${tmp_home}/.config/example/missing"* ]] ||
        fail "expected doctor to report the missing managed link"
    [[ "$output" == *"not a symlink: ${tmp_home}/.config/example/regular"* ]] ||
        fail "expected doctor to report the regular-file conflict"
    [[ "$output" == *"wrong target: ${tmp_home}/.config/example/wrong -> ${tmpdir}/other-target"* ]] ||
        fail "expected doctor to report the wrong symlink target"
    [[ "$output" != *"${tmp_home}/.config/example/good"* ]] ||
        fail "expected doctor to accept the correctly linked managed file"

    rm -rf "$tmpdir"
}

main() {
    step "Running dotfiles doctor tests"
    test_reports_broken_dotfiles_package_symlinks
    ok "reports broken dotfiles package symlinks"
    test_succeeds_without_broken_dotfiles_package_symlinks
    ok "succeeds without broken dotfiles package symlinks"
    test_reports_managed_dotfile_link_issues
    ok "reports managed dotfile link issues"
}

main "$@"
