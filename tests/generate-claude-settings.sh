#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/ui.sh"

GENERATOR="${REPO_ROOT}/scripts/generate-claude-settings.sh"

fail() {
    warn "$*"
    exit 1
}

test_generates_settings_from_shared_and_local_sources() {
    local tmpdir
    local source_dir
    local target_file

    tmpdir="$(mktemp -d /tmp/generate-claude-settings.XXXXXX)"
    source_dir="${tmpdir}/_settings-source"
    target_file="${tmpdir}/.claude/settings.json"
    mkdir -p "$source_dir"

    cat >"${source_dir}/shared.json" <<'JSON'
{
  "permissions": {
    "allow": ["Bash(git status:*)"],
    "deny": ["Bash(curl:*)"]
  },
  "enabledPlugins": {
    "shared-plugin": true,
    "machine-plugin": false
  }
}
JSON

    cat >"${source_dir}/company.json" <<'JSON'
{
  "permissions": {
    "allow": ["Bash(git status:*)", "Bash(gh pr view:*)"],
    "deny": ["Bash(wget:*)"]
  },
  "enabledPlugins": {
    "machine-plugin": true
  }
}
JSON

    DOTFILES_CLAUDE_SETTINGS_SOURCE_DIR="$source_dir" \
        DOTFILES_CLAUDE_SETTINGS_TARGET="$target_file" \
        bash "$GENERATOR" >/dev/null

    jq -e '
      .permissions.allow == ["Bash(git status:*)", "Bash(gh pr view:*)"]
      and .permissions.deny == ["Bash(curl:*)", "Bash(wget:*)"]
      and .enabledPlugins["shared-plugin"] == true
      and .enabledPlugins["machine-plugin"] == true
    ' "$target_file" >/dev/null ||
        fail "expected generated settings to merge shared and local sources"

    rm -rf "$tmpdir"
}

main() {
    step "Running Claude settings generator tests"
    test_generates_settings_from_shared_and_local_sources
    ok "generates settings from shared and local sources"
}

main "$@"
