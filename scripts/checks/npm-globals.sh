#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UI_HELPERS="$DOTFILES_DIR/scripts/lib/ui.sh"
. "$UI_HELPERS"

STEP_ICON="${STEP_ICON:-🔍}"

step "npm global packages (outdated only)"

if ! command -v npm >/dev/null 2>&1; then
  warn "npm not installed"
  exit 0
fi

list_file="$DOTFILES_DIR/packages/npm/global-packages.txt"
if [[ ! -f "$list_file" ]]; then
  warn "global-packages.txt not found"
  exit 0
fi

# npm outdated exits 1 when updates exist; treat >1 as an error.
set +e
outdated_output=$(npm outdated -g --depth=0 --parseable --long 2>/dev/null)
status=$?
set -e

if [[ $status -gt 1 ]]; then
  warn "npm outdated -g failed (exit $status)"
  exit 0
fi

wanted_list=$(grep -vE '^(#|$)' "$list_file")
found=0

# parseable format: path:package:current:wanted:latest:type:homepage
while IFS=: read -r _ pkg_name current wanted_ver latest _rest; do
  [[ -z "$pkg_name" ]] && continue
  if printf "%s\n" "$wanted_list" | grep -Fxq "$pkg_name"; then
    found=1
    printf "  [OUTDATED] %s %s -> %s\n" "$pkg_name" "$current" "$latest"
  fi
done <<< "$outdated_output"

if [[ $found -eq 0 ]]; then
  printf "  [OK] All pinned npm globals are up-to-date.\n"
fi
