#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

UI_HELPERS="$DOTFILES_DIR/scripts/lib/ui.sh"
. "$UI_HELPERS"

STEP_ICON="🩺"

usage() {
  cat <<'EOF'
Usage: doctor.sh

Diagnose local dotfiles health without changing files.

Currently checks for broken symlinks that point back into this repository's
packages/ tree.
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

main() {
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

  if report_broken_dotfiles_symlinks; then
    ok "Doctor finished"
  else
    warn "Doctor finished with warnings"
    return 1
  fi
}

main "$@"
