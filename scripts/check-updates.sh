#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

UI_HELPERS="$DOTFILES_DIR/scripts/lib/ui.sh"
. "$UI_HELPERS"

STEP_ICON="🔍"

banner() {
  local border="${CYAN}${LINE_EQUAL}${RESET}"
  printf "%s\n" "$border"
  echo "${BOLD}${CYAN}🔎 Checking dotfiles updates${RESET}"
  printf "%s\n\n" "$border"
}

usage() {
  cat <<'EOF'
Usage: check-updates.sh [check...]
Checks:
  brew      Homebrew outdated
  mise      mise outdated
  sheldon   sheldon plugin pinned revs
Options:
  --list    Show available checks
  --help    Show this message
If no checks are provided, all run in order.
EOF
}

resolve_script() {
  case "$1" in
    brew) echo "$DOTFILES_DIR/scripts/checks/brew-outdated.sh" ;;
    mise) echo "$DOTFILES_DIR/scripts/checks/mise-outdated.sh" ;;
    sheldon) echo "$DOTFILES_DIR/scripts/checks/sheldon-pins.sh" ;;
    *) return 1 ;;
  esac
}

run_checks() {
  local checks=("$@")
  if [ ${#checks[@]} -eq 0 ]; then
    checks=(brew mise sheldon)
  fi

  for check in "${checks[@]}"; do
    script_path="$(resolve_script "$check")" || { warn "Unknown check '$check'"; continue; }
    if [ ! -x "$script_path" ]; then
      warn "Check script missing or not executable: $script_path"
      continue
    fi
    if ! "$script_path"; then
      warn "Check '$check' failed"
    fi
  done
}

next_steps() {
  step "Next steps"
  printf "%s  • Homebrew:%s run 'brew upgrade <pkg>' (or 'brew upgrade' for all)\n" "$MAGENTA" "$RESET"
  printf "%s  • mise:%s edit packages/mise/.config/mise/config.toml, then run 'mise install <tool>'\n" "$MAGENTA" "$RESET"
  printf "%s  • sheldon:%s bump rev in packages/sheldon/.config/sheldon/plugins.toml and run 'sheldon lock --relock'\n" "$MAGENTA" "$RESET"
}

main() {
  case "${1:-}" in
    --help|-h) usage; exit 0 ;;
    --list) printf "brew\nmise\nsheldon\n"; exit 0 ;;
  esac

  banner
  run_checks "$@"
  printf "\n"
  next_steps
  printf "\n"
  ok "Checks finished"
}

main "$@"
