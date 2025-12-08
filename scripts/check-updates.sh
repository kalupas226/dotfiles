#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

info() { printf "\n==> %s\n" "$*"; }

# 1) Homebrew updates (metadata + outdated list)
if command -v brew >/dev/null 2>&1; then
  info "brew outdated"
  brew update --quiet || info "brew update failed"
  HOMEBREW_NO_INSTALL_CLEANUP=1 brew outdated || info "brew outdated failed"
else
  info "brew not installed"
fi

# 2) mise tool updates (does not install anything)
if command -v mise >/dev/null 2>&1; then
  info "mise outdated"
  (cd "$REPO_ROOT" && mise outdated) || info "mise outdated failed"
else
  info "mise not installed"
fi

# 3) Neovim plugin updates via lazy.nvim
if command -v nvim >/dev/null 2>&1; then
  info "Neovim Lazy check"
  NVIM_CFG="$REPO_ROOT/packages/nvim/.config"
  if [[ -d "$NVIM_CFG/nvim" ]]; then
    # Run with repo config, but keep caches/data in a temp dir to avoid polluting the user's ~/.local/share ~/.cache
    TMP_BASE="${TMPDIR:-/tmp}/lazy-check-$$"
    cleanup() { [[ -d "$TMP_BASE" ]] && rm -rf "$TMP_BASE"; }
    trap cleanup EXIT

    LAZY_LOG="$TMP_BASE/lazy.log"
    mkdir -p "$TMP_BASE/share" "$TMP_BASE/state" "$TMP_BASE/cache"
    XDG_CONFIG_HOME="$NVIM_CFG" \
    XDG_DATA_HOME="$TMP_BASE/share" \
    XDG_STATE_HOME="$TMP_BASE/state" \
    XDG_CACHE_HOME="$TMP_BASE/cache" \
    nvim --headless "+Lazy! sync" "+Lazy! check" "+qa" >"$LAZY_LOG" 2>&1 || info "lazy check failed"
    if [[ -s "$LAZY_LOG" ]]; then
      info "Neovim Lazy summary"
      if grep -iE "update|outdated|upgrade|changed|new version|available" "$LAZY_LOG"; then
        true
      else
        info "No obvious update lines; showing last 20 log lines"
        tail -n 20 "$LAZY_LOG"
      fi
    fi
    cleanup
    trap - EXIT
  else
    info "nvim config not found at $NVIM_CFG/nvim"
  fi
else
  info "nvim not installed"
fi

# 4) sheldon plugins: compare pinned rev with latest tag
if command -v git >/dev/null 2>&1; then
  info "sheldon plugin rev check"
  plugins_file="$REPO_ROOT/packages/sheldon/.config/sheldon/plugins.toml"
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
    info "plugins.toml not found"
  fi
else
  info "git not installed"
fi

info "Next steps if updates were reported"
printf "  - Homebrew: run 'brew upgrade <pkg>' (or 'brew upgrade' for all)\n"
printf "  - mise: edit packages/mise/.config/mise.toml, then run 'mise install <tool>'\n"
printf "  - Neovim: run 'nvim --headless \"+Lazy update\" \"+qa\"' (or inside nvim run :Lazy update)\n"
printf "  - sheldon: bump rev in packages/sheldon/.config/sheldon/plugins.toml and run 'sheldon lock --relock'\n"

printf "\nDone.\n"
