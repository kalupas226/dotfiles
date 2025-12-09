#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

UI_HELPERS="$DOTFILES_DIR/scripts/lib/ui.sh"
. "$UI_HELPERS"

# Override icons for this script (checks only)
STEP_ICON="🔍"

# Banner
border="${CYAN}${LINE_EQUAL}${RESET}"
printf "%s\n" "$border"
echo "${BOLD}${CYAN}🔎 Checking dotfiles updates${RESET}"
printf "%s\n\n" "$border"

# 1) Homebrew outdated (metadata + list)
step "Homebrew outdated"
if command -v brew >/dev/null 2>&1; then
  note "brew outdated (no auto-update)"
  HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew outdated || warn "brew outdated failed"
else
  warn "brew not installed"
fi

# 2) mise tool updates (does not install anything)
step "mise outdated"
if command -v mise >/dev/null 2>&1; then
  (cd "$DOTFILES_DIR" && mise outdated) || warn "mise outdated failed"
else
  warn "mise not installed"
fi

# 3) sheldon plugins: compare pinned rev with latest tag
step "sheldon plugin rev check"
if command -v git >/dev/null 2>&1; then
  plugins_file="$DOTFILES_DIR/packages/sheldon/.config/sheldon/plugins.toml"
  if [[ -f "$plugins_file" ]]; then
    while read -r name repo rev; do
      [[ -z "$rev" ]] && continue
      latest_tag=$(git ls-remote --tags "https://github.com/${repo}.git" 2>/dev/null \
        | awk '{print $2}' | sed 's#refs/tags/##' | grep -v '\^{}' \
        | sort -V | tail -1)
      tag_present=$(git ls-remote "https://github.com/${repo}.git" "refs/tags/${rev}" 2>/dev/null || true)
      if [[ -z "$tag_present" ]]; then
        printf "  [!] %s: pinned %s (not found upstream)\n" "$name" "$rev"
      else
        printf "  [OK] %s: pinned %s (latest tag: %s)\n" "$name" "$rev" "${latest_tag:-unknown}"
      fi
    done < <(
      awk '
        /^\[plugins\./ {p=$0; sub(/^\[plugins\./,"",p); sub(/\]/,"",p)}
        /^github/ {split($3,a,"\""); repo[a[2]]=$0; repos[p]=a[2]}
        /^rev/ {split($3,a,"\""); revs[p]=a[2]}
        END {for (p in repos) printf "%s %s %s\n", p, repos[p], revs[p]}
      ' "$plugins_file"
    )
  else
    warn "plugins.toml not found"
  fi
else
  warn "git not installed"
fi

step "Next steps"
printf "%s  • Homebrew:%s run 'brew upgrade <pkg>' (or 'brew upgrade' for all)\n" "$MAGENTA" "$RESET"
printf "%s  • mise:%s edit packages/mise/.config/mise.toml, then run 'mise install <tool>'\n" "$MAGENTA" "$RESET"
printf "%s  • sheldon:%s bump rev in packages/sheldon/.config/sheldon/plugins.toml and run 'sheldon lock --relock'\n" "$MAGENTA" "$RESET"

printf "\n"
ok "Checks finished"
