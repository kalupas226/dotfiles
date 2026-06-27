#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

UI_HELPERS="$DOTFILES_DIR/scripts/lib/ui.sh"
# shellcheck source=/dev/null
. "$UI_HELPERS"

SOURCE_DIR="${DOTFILES_CLAUDE_SETTINGS_SOURCE_DIR:-$HOME/.claude/_settings-source}"
TARGET_FILE="${DOTFILES_CLAUDE_SETTINGS_TARGET:-$HOME/.claude/settings.json}"

usage() {
  cat <<'EOF'
Usage:
  dotfiles claude-settings
  scripts/generate-claude-settings.sh

Generate ~/.claude/settings.json from JSON files in:
  ~/.claude/_settings-source/

shared.json is merged first. Other *.json files are merged afterwards in
lexicographic order.
EOF
}

# This is jq code, so shell variables inside the single-quoted string are
# intentionally not expanded by the shell.
# shellcheck disable=SC2016
json_merge_filter='
def unique_stable:
  reduce .[] as $item ([]; if index($item) == null then . + [$item] else . end);

def merge(a; b):
  if (a | type) == "object" and (b | type) == "object" then
    reduce (b | keys_unsorted[]) as $key (
      a;
      .[$key] = if has($key) then merge(.[$key]; b[$key]) else b[$key] end
    )
  elif (a | type) == "array" and (b | type) == "array" then
    (a + b) | unique_stable
  else
    b
  end;

reduce .[] as $item ({}; merge(.; $item))
'

main() {
  local target_dir
  local tmp_file
  local file
  local -a source_files
  local -a other_files

  case "${1:-}" in
    --help|-h)
      usage
      return 0
      ;;
    "")
      ;;
    *)
      warn "Unknown option: $1"
      usage
      return 1
      ;;
  esac

  step "Generating Claude Code settings"

  if ! command -v jq >/dev/null 2>&1; then
    warn "jq not found; cannot generate Claude Code settings"
    return 1
  fi

  if [ ! -d "$SOURCE_DIR" ]; then
    warn "Claude settings source directory not found: $SOURCE_DIR"
    return 1
  fi

  source_files=()
  if [ -f "$SOURCE_DIR/shared.json" ]; then
    source_files+=("$SOURCE_DIR/shared.json")
  fi

  shopt -s nullglob
  other_files=("$SOURCE_DIR"/*.json)
  shopt -u nullglob

  for file in "${other_files[@]}"; do
    if [ "$(basename "$file")" = "shared.json" ]; then
      continue
    fi
    source_files+=("$file")
  done

  if [ ${#source_files[@]} -eq 0 ]; then
    warn "No Claude settings source files found in: $SOURCE_DIR"
    return 1
  fi

  target_dir="$(dirname "$TARGET_FILE")"
  mkdir -p "$target_dir"
  tmp_file="$(mktemp "${TARGET_FILE}.tmp.XXXXXX")"

  if jq -S -s "$json_merge_filter" "${source_files[@]}" > "$tmp_file"; then
    mv -f "$tmp_file" "$TARGET_FILE"
    ok "Generated $TARGET_FILE"
  else
    rm -f "$tmp_file"
    warn "Failed to generate $TARGET_FILE"
    return 1
  fi
}

main "$@"
