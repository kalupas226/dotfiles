#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UI_HELPERS="$DOTFILES_DIR/scripts/lib/ui.sh"
. "$UI_HELPERS"

STEP_ICON="${STEP_ICON:-🔍}"

command -v git >/dev/null 2>&1 || { warn "git not installed"; exit 0; }

plugins_file="$DOTFILES_DIR/packages/sheldon/.config/sheldon/plugins.toml"
[[ -f "$plugins_file" ]] || { warn "plugins.toml not found"; exit 0; }

step "sheldon plugin rev check"
while read -r name repo rev; do
  [[ -z "$rev" ]] && continue
  latest_tag=$(
    git ls-remote --tags --sort=-version:refname "https://github.com/${repo}.git" 2>/dev/null \
      | awk '{print $2}' \
      | sed 's#refs/tags/##' \
      | grep -v '\^{}' \
      | head -1 \
      || true
  )
  if [[ -z "$latest_tag" ]]; then
    printf "  [?] %s: pinned %s (could not fetch tags)\n" "$name" "$rev"
  elif [[ "$rev" != "$latest_tag" ]]; then
    printf "  [OUTDATED] %s: pinned %s -> latest %s\n" "$name" "$rev" "$latest_tag"
  else
    printf "  [OK] %s: %s\n" "$name" "$rev"
  fi
done < <(
  awk '
    /^\[plugins\./ {p=$0; sub(/^\[plugins\./,"",p); sub(/\]/,"",p)}
    /^github[[:space:]]*=/ {split($3,a,"\""); repos[p]=a[2]}
    /^rev[[:space:]]*=/ {split($3,a,"\""); revs[p]=a[2]}
    END {for (p in repos) printf "%s %s %s\n", p, repos[p], revs[p]}
  ' "$plugins_file"
)
