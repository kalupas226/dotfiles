#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UI_HELPERS="$DOTFILES_DIR/scripts/lib/ui.sh"
. "$UI_HELPERS"

STEP_ICON="${STEP_ICON:-🔍}"

step "mise outdated"
if command -v mise >/dev/null 2>&1; then
  (cd "$DOTFILES_DIR" && mise outdated) || warn "mise outdated failed"
else
  warn "mise not installed"
fi
