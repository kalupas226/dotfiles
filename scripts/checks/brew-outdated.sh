#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UI_HELPERS="$DOTFILES_DIR/scripts/lib/ui.sh"
. "$UI_HELPERS"

STEP_ICON="${STEP_ICON:-🔍}"

step "Homebrew outdated"
if command -v brew >/dev/null 2>&1; then
  note "brew update --quiet"
  HOMEBREW_NO_INSTALL_CLEANUP=1 brew update --quiet || warn "brew update failed"
  note "brew outdated"
  HOMEBREW_NO_INSTALL_CLEANUP=1 brew outdated || warn "brew outdated failed"
else
  warn "brew not installed"
fi
