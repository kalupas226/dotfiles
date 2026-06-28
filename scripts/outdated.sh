#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

UI_HELPERS="$DOTFILES_DIR/scripts/lib/ui.sh"
. "$UI_HELPERS"

STEP_ICON="🔍"
REFRESH=0
SOURCES=(brew mise sheldon)
SOURCE_DESCRIPTIONS=(
  "Homebrew outdated"
  "mise outdated"
  "sheldon plugin pinned revs"
)
REQUESTED_SOURCES=()

banner() {
  local border="${CYAN}${LINE_EQUAL}${RESET}"
  printf "%s\n" "$border"
  echo "${BOLD}${CYAN}🔎 Checking dotfiles outdated sources${RESET}"
  printf "%s\n\n" "$border"
}

usage() {
  cat <<'EOF'
Usage: outdated.sh [--refresh] [source...]
Sources:
EOF
  local i
  for i in "${!SOURCES[@]}"; do
    printf "  %-8s %s\n" "${SOURCES[$i]}" "${SOURCE_DESCRIPTIONS[$i]}"
  done
  cat <<'EOF'
Options:
  --refresh    Refresh update metadata before supported sources
  --list       Show available sources
  --help       Show this message
If no sources are provided, all run in order.
EOF
}

list_sources() {
  printf "%s\n" "${SOURCES[@]}"
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --help|-h)
        usage
        exit 0
        ;;
      --list)
        list_sources
        exit 0
        ;;
      --refresh)
        REFRESH=1
        shift
        ;;
      --)
        shift
        REQUESTED_SOURCES+=("$@")
        break
        ;;
      -*)
        warn "Unknown option '$1'"
        return 1
        ;;
      *)
        REQUESTED_SOURCES+=("$1")
        shift
        ;;
    esac
  done
}

resolve_script() {
  case "$1" in
    brew) echo "$DOTFILES_DIR/scripts/outdated/brew-outdated.sh" ;;
    mise) echo "$DOTFILES_DIR/scripts/outdated/mise-outdated.sh" ;;
    sheldon) echo "$DOTFILES_DIR/scripts/outdated/sheldon-pins.sh" ;;
    *) return 1 ;;
  esac
}

run_sources() {
  local sources=("$@")
  local failed=0
  local script_path
  if [ ${#sources[@]} -eq 0 ]; then
    sources=("${SOURCES[@]}")
  fi

  for source in "${sources[@]}"; do
    script_path="$(resolve_script "$source")" || { warn "Unknown source '$source'"; failed=1; continue; }
    if [ ! -x "$script_path" ]; then
      warn "Outdated source script missing or not executable: $script_path"
      failed=1
      continue
    fi
    if ! DOTFILES_OUTDATED_REFRESH="$REFRESH" "$script_path"; then
      warn "Outdated source '$source' failed"
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
  if run_sources ${REQUESTED_SOURCES[@]+"${REQUESTED_SOURCES[@]}"}; then
    result=0
  else
    result=$?
  fi
  printf "\n"
  next_steps
  printf "\n"
  if [ "$result" -eq 0 ]; then
    ok "Outdated checks finished"
  else
    warn "Outdated checks finished with warnings"
  fi
  return "$result"
}

main "$@"
