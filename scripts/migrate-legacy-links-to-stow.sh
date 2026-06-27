#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

UI_HELPERS="$DOTFILES_DIR/scripts/lib/ui.sh"
# shellcheck source=/dev/null
. "$UI_HELPERS"

DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: migrate-legacy-links-to-stow.sh [--dry-run]

Remove symlinks created by the old install.sh so GNU Stow can take over.
Only symlinks that already point at the same file under packages/ are removed.
Regular files and symlinks to any other target are left untouched.
EOF
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run|-n)
        DRY_RUN=1
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        warn "Unknown option: $1"
        usage
        return 1
        ;;
    esac
  done
}

main() {
  local source_file
  local package_relative_path
  local package_name
  local relative_path
  local target_file
  local target_link
  local count=0

  parse_args "$@"

  if [ "$DRY_RUN" -eq 1 ]; then
    step "Checking legacy dotfile symlinks"
  else
    step "Migrating legacy dotfile symlinks"
  fi

  while IFS= read -r source_file; do
    package_relative_path="${source_file#"${DOTFILES_DIR}"/packages/}"
    package_name="${package_relative_path%%/*}"
    relative_path="${package_relative_path#"${package_name}"/}"
    target_file="${HOME}/${relative_path}"

    if [ ! -L "$target_file" ]; then
      continue
    fi

    target_link="$(readlink "$target_file")"
    if [ "$target_link" != "$source_file" ]; then
      continue
    fi

    count=$((count + 1))
    if [ "$DRY_RUN" -eq 1 ]; then
      note "Would remove $target_file"
    else
      rm "$target_file"
      ok "Removed $target_file"
    fi
  done < <(find "${DOTFILES_DIR}/packages" -type f)

  if [ "$count" -eq 0 ]; then
    skip "No legacy dotfile symlinks found"
  elif [ "$DRY_RUN" -eq 1 ]; then
    note "Found ${count} legacy dotfile symlinks"
  else
    ok "Removed ${count} legacy dotfile symlinks"
  fi
}

main "$@"
