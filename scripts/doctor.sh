#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_DIR="${DOTFILES_DOCTOR_PACKAGES_DIR:-$DOTFILES_DIR/packages}"

UI_HELPERS="$DOTFILES_DIR/scripts/lib/ui.sh"
# shellcheck source=scripts/lib/ui.sh
. "$UI_HELPERS"

STEP_ICON="🩺"

usage() {
  cat <<'EOF'
Usage: doctor.sh

Diagnose local dotfiles health without changing files.

Checks for broken symlinks that point back into this repository's packages/
tree, and verifies that every managed package file is linked under $HOME.
EOF
}

load_scan_roots() {
  if [ -n "${DOTFILES_DOCTOR_SCAN_ROOTS:-}" ]; then
    IFS=: read -r -a SCAN_ROOTS <<< "$DOTFILES_DOCTOR_SCAN_ROOTS"
  else
    SCAN_ROOTS=(
      "$HOME/.local/bin"
      "$HOME/.local/libexec"
      "$HOME/.config"
      "$HOME/.claude"
    )
  fi
}

candidate_symlinks() {
  local root

  find "$HOME" -maxdepth 1 -type l 2>/dev/null || true
  for root in "${SCAN_ROOTS[@]}"; do
    [ -e "$root" ] || [ -L "$root" ] || continue
    find "$root" -type l 2>/dev/null || true
  done
}

points_to_dotfiles_packages() {
  local link="$1"
  local target="$2"
  local repo_name
  local link_dir

  repo_name="$(basename "$DOTFILES_DIR")"
  case "$target" in
    "$DOTFILES_DIR"/packages/*|*/"$repo_name"/packages/*)
      return 0
      ;;
  esac

  link_dir="$(cd -- "$(dirname -- "$link")" && pwd -P 2>/dev/null)" || return 1
  case "$link_dir/$target" in
    "$DOTFILES_DIR"/packages/*|*/"$repo_name"/packages/*)
      return 0
      ;;
  esac

  return 1
}

report_broken_dotfiles_symlinks() {
  local link
  local target
  local count=0

  step "Broken dotfiles symlinks"

  while IFS= read -r link; do
    [ -L "$link" ] || continue
    [ ! -e "$link" ] || continue

    target="$(readlink "$link")" || continue
    points_to_dotfiles_packages "$link" "$target" || continue

    printf "  %s -> %s\n" "$link" "$target"
    count=$((count + 1))
  done < <(candidate_symlinks)

  if [ "$count" -eq 0 ]; then
    ok "No broken dotfiles symlinks found"
    return 0
  fi

  warn "Found ${count} broken dotfiles symlink(s)"
  note "Review the links above, remove the stale symlinks, then relink the affected packages."
  return 1
}

report_managed_dotfile_links() {
  local source_file
  local package_relative_path
  local package_name
  local relative_path
  local target_file
  local target_link
  local count=0

  step "Managed dotfile links"

  if [ ! -d "$PACKAGES_DIR" ]; then
    warn "Packages directory not found: $PACKAGES_DIR"
    return 1
  fi

  while IFS= read -r source_file; do
    package_relative_path="${source_file#"${PACKAGES_DIR}"/}"
    package_name="${package_relative_path%%/*}"
    relative_path="${package_relative_path#"${package_name}"/}"
    target_file="${HOME}/${relative_path}"

    if [ ! -e "$target_file" ] && [ ! -L "$target_file" ]; then
      printf "  missing: %s\n" "$target_file"
    elif [ ! -L "$target_file" ]; then
      printf "  not a symlink: %s\n" "$target_file"
    elif [ ! "$target_file" -ef "$source_file" ]; then
      target_link="$(readlink "$target_file" 2>/dev/null || true)"
      printf "  wrong target: %s -> %s\n" "$target_file" "$target_link"
    else
      continue
    fi

    count=$((count + 1))
  done < <(find "$PACKAGES_DIR" -type f)

  if [ "$count" -eq 0 ]; then
    ok "All managed dotfiles are linked"
    return 0
  fi

  warn "Found ${count} managed dotfile link issue(s)"
  note "Review the paths above, resolve any conflicts, then run 'dotfiles install'."
  return 1
}

main() {
  local failed=0

  case "${1:-}" in
    --help|-h)
      usage
      return 0
      ;;
    "")
      ;;
    *)
      warn "Unknown option: $1"
      usage
      return 1
      ;;
  esac

  load_scan_roots

  report_broken_dotfiles_symlinks || failed=1
  report_managed_dotfile_links || failed=1

  if [ "$failed" -eq 0 ]; then
    ok "Doctor finished"
  else
    warn "Doctor finished with warnings"
    return 1
  fi
}

main "$@"
