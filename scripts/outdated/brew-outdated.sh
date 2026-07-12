#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UI_HELPERS="$DOTFILES_DIR/scripts/lib/ui.sh"
# shellcheck source=scripts/lib/ui.sh
. "$UI_HELPERS"

STEP_ICON="${STEP_ICON:-🔍}"
failed=0

step "Homebrew outdated"
if command -v brew >/dev/null 2>&1; then
  if [[ "${DOTFILES_OUTDATED_REFRESH:-0}" == "1" ]]; then
    note "brew update --quiet"
    if ! HOMEBREW_NO_INSTALL_CLEANUP=1 brew update --quiet; then
      warn "brew update failed"
      failed=1
    fi
  else
    skip "Skipping brew update; pass --refresh to update Homebrew metadata first"
  fi
  note "brew outdated"
  if ! HOMEBREW_NO_INSTALL_CLEANUP=1 brew outdated; then
    warn "brew outdated failed"
    failed=1
  fi
else
  warn "brew not installed"
  failed=1
fi

exit "$failed"
