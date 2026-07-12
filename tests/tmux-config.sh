#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/ui.sh"

TMUX_CONF="${REPO_ROOT}/packages/tmux/.tmux.conf"
TMUX_TEST_TMPDIR=""
TMUX_TEST_HOME=""
TMUX_TEST_SOCKET="dotfiles-config-test"

fail() {
    warn "$*"
    exit 1
}

cleanup_tmux_test() {
    if [[ -n "$TMUX_TEST_TMPDIR" ]]; then
        HOME="$TMUX_TEST_HOME" TMUX_TMPDIR="$TMUX_TEST_TMPDIR" tmux -L "$TMUX_TEST_SOCKET" kill-server >/dev/null 2>&1 || true
        rm -rf "$TMUX_TEST_TMPDIR"
    fi
}

test_tmux_config_uses_pane_current_path() {
    local split_right
    local split_down
    local shell_popup
    local lazygit_popup
    local project_picker
    local file_refs
    local removed_alias
    local removed_binding

    TMUX_TEST_TMPDIR="$(mktemp -d /tmp/dotfiles-tmux-config.XXXXXX)"
    TMUX_TEST_HOME="${TMUX_TEST_TMPDIR}/home"
    mkdir -p "$TMUX_TEST_HOME"
    trap cleanup_tmux_test EXIT

    HOME="$TMUX_TEST_HOME" TMUX_TMPDIR="$TMUX_TEST_TMPDIR" tmux -L "$TMUX_TEST_SOCKET" -f "$TMUX_CONF" new-session -d

    split_right="$(HOME="$TMUX_TEST_HOME" TMUX_TMPDIR="$TMUX_TEST_TMPDIR" tmux -L "$TMUX_TEST_SOCKET" show-options -sv 'command-alias[100]')"
    split_down="$(HOME="$TMUX_TEST_HOME" TMUX_TMPDIR="$TMUX_TEST_TMPDIR" tmux -L "$TMUX_TEST_SOCKET" show-options -sv 'command-alias[101]')"
    shell_popup="$(HOME="$TMUX_TEST_HOME" TMUX_TMPDIR="$TMUX_TEST_TMPDIR" tmux -L "$TMUX_TEST_SOCKET" show-options -sv 'command-alias[108]')"
    lazygit_popup="$(HOME="$TMUX_TEST_HOME" TMUX_TMPDIR="$TMUX_TEST_TMPDIR" tmux -L "$TMUX_TEST_SOCKET" show-options -sv 'command-alias[109]')"
    project_picker="$(HOME="$TMUX_TEST_HOME" TMUX_TMPDIR="$TMUX_TEST_TMPDIR" tmux -L "$TMUX_TEST_SOCKET" show-options -sv 'command-alias[111]')"
    file_refs="$(HOME="$TMUX_TEST_HOME" TMUX_TMPDIR="$TMUX_TEST_TMPDIR" tmux -L "$TMUX_TEST_SOCKET" show-options -sv 'command-alias[113]')"

    [[ "$split_right" == *'split-window -h -c "#{pane_current_path}"'* ]] ||
        fail "expected horizontal split to use pane_current_path"
    [[ "$split_down" == *'split-window -v -c "#{pane_current_path}"'* ]] ||
        fail "expected vertical split to use pane_current_path"
    [[ "$shell_popup" == *'display-popup -d "#{pane_current_path}"'* ]] ||
        fail "expected shell popup to use pane_current_path"
    [[ "$lazygit_popup" == *'display-popup -d "#{pane_current_path}"'* ]] ||
        fail "expected lazygit popup to use pane_current_path"
    [[ "$project_picker" == *'.local/libexec/tmux/project'* ]] ||
        fail "expected project picker alias to remain available"
    [[ "$file_refs" == *'.local/libexec/tmux/file-refs'* ]] ||
        fail "expected file reference alias to remain available"

    removed_alias="$(HOME="$TMUX_TEST_HOME" TMUX_TMPDIR="$TMUX_TEST_TMPDIR" tmux -L "$TMUX_TEST_SOCKET" show-options -sv 'command-alias[110]' 2>/dev/null || true)"
    if [[ -n "$removed_alias" ]]; then
        fail "expected removed lazygit pane alias to be unset"
    fi
    removed_binding="$(HOME="$TMUX_TEST_HOME" TMUX_TMPDIR="$TMUX_TEST_TMPDIR" tmux -L "$TMUX_TEST_SOCKET" list-keys -T prefix G 2>/dev/null || true)"
    if [[ -n "$removed_binding" ]]; then
        fail "expected prefix + G to be unbound"
    fi

    if grep -E 'Claude-aware|\.local/libexec/tmux/open|run-in-pane|my-lazygit-bottom-pane' "$TMUX_CONF" >/dev/null; then
        fail "expected removed tmux helpers to be absent from tmux config"
    fi

    trap - EXIT
    cleanup_tmux_test
}

main() {
    step "Running tmux config tests"
    test_tmux_config_uses_pane_current_path
    ok "uses pane current path without Claude-aware helpers"
}

main "$@"
