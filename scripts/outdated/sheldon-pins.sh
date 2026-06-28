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
    printf "  %s (%s) ? unknown\n" "$name" "$rev"
  elif [[ "$rev" != "$latest_tag" ]]; then
    printf "  %s (%s) < %s\n" "$name" "$rev" "$latest_tag"
  else
    printf "  %s (%s) = %s\n" "$name" "$rev" "$latest_tag"
  fi
done < <(
  awk '
    function emit() {
      if (plugin != "" && repo != "") {
        printf "%s %s %s\n", plugin, repo, rev
      }
    }
    /^\[plugins\./ {
      emit()
      plugin=$0
      sub(/^\[plugins\./,"",plugin)
      sub(/\]/,"",plugin)
      repo=""
      rev=""
    }
    /^github[[:space:]]*=/ {split($3,a,"\""); repo=a[2]}
    /^rev[[:space:]]*=/ {split($3,a,"\""); rev=a[2]}
    END {emit()}
  ' "$plugins_file"
)
