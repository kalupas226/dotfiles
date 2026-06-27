#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

UI_HELPERS="$DOTFILES_DIR/scripts/lib/ui.sh"
. "$UI_HELPERS"

STEP_ICON="🔍"
REFRESH=0
CHECKS=(brew mise sheldon)
CHECK_DESCRIPTIONS=(
  "Homebrew outdated"
  "mise outdated"
  "sheldon plugin pinned revs"
)
REQUESTED_CHECKS=()

banner() {
  local border="${CYAN}${LINE_EQUAL}${RESET}"
  printf "%s\n" "$border"
  echo "${BOLD}${CYAN}🔎 Checking dotfiles updates${RESET}"
  printf "%s\n\n" "$border"
}

usage() {
  cat <<'EOF'
Usage: check-updates.sh [--refresh] [check...]
Checks:
EOF
  local i
  for i in "${!CHECKS[@]}"; do
    printf "  %-8s %s\n" "${CHECKS[$i]}" "${CHECK_DESCRIPTIONS[$i]}"
  done
  cat <<'EOF'
Options:
  --refresh    Refresh update metadata before supported checks
  --list       Show available checks
  --help       Show this message
If no checks are provided, all run in order.
EOF
}

list_checks() {
  printf "%s\n" "${CHECKS[@]}"
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --help|-h)
        usage
        exit 0
        ;;
      --list)
        list_checks
        exit 0
        ;;
      --refresh)
        REFRESH=1
        shift
        ;;
      --)
        shift
        REQUESTED_CHECKS+=("$@")
        break
        ;;
      -*)
        warn "Unknown option '$1'"
        return 1
        ;;
      *)
        REQUESTED_CHECKS+=("$1")
        shift
        ;;
    esac
  done
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
  local failed=0
  local script_path
  if [ ${#checks[@]} -eq 0 ]; then
    checks=("${CHECKS[@]}")
  fi

  for check in "${checks[@]}"; do
    script_path="$(resolve_script "$check")" || { warn "Unknown check '$check'"; failed=1; continue; }
    if [ ! -x "$script_path" ]; then
      warn "Check script missing or not executable: $script_path"
      failed=1
      continue
    fi
    if ! DOTFILES_CHECK_REFRESH="$REFRESH" "$script_path"; then
      warn "Check '$check' failed"
      failed=1
    fi
  done

  return "$failed"
}

next_steps() {
  step "Next steps"
  printf "%s  • Homebrew:%s run 'brew upgrade <pkg>' (or 'brew upgrade' for all)\n" "$MAGENTA" "$RESET"
  printf "%s  • mise:%s edit packages/mise/.config/mise/config.toml, then run 'mise install <tool>'\n" "$MAGENTA" "$RESET"
  printf "%s  • sheldon:%s bump rev in packages/sheldon/.config/sheldon/plugins.toml and run 'sheldon lock --relock'\n" "$MAGENTA" "$RESET"
}

main() {
  local result

  parse_args "$@" || return 1

  banner
  if run_checks "${REQUESTED_CHECKS[@]}"; then
    result=0
  else
    result=$?
  fi
  printf "\n"
  next_steps
  printf "\n"
  if [ "$result" -eq 0 ]; then
    ok "Checks finished"
  else
    warn "Checks finished with warnings"
  fi
  return "$result"
}

main "$@"
