#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/ui.sh"

TMUX_OPEN="${REPO_ROOT}/packages/bin/.local/bin/tmux-open"

fail() {
    warn "$*"
    exit 1
}

write_tmux_wrapper() {
    local wrapper_path="$1"
    local tmux_log="$2"

    cat >"$wrapper_path" <<EOF
#!/usr/bin/env bash
set -euo pipefail

cmd="\${1:-}"
shift || true
printf '%s' "\$cmd" >>"${tmux_log}"
for arg in "\$@"; do
    printf ' %s' "\$arg" >>"${tmux_log}"
done
printf '\n' >>"${tmux_log}"

case "\$cmd" in
    show-options)
        option="\${!#}"
        case "\$option" in
            @preferred_cwd)
                printf '%s\n' "\${TMUX_TEST_PREFERRED_CWD:-}"
                ;;
            @preferred_cwd_owner)
                printf '%s\n' "\${TMUX_TEST_OWNER:-}"
                ;;
            @preferred_cwd_updated_at)
                printf '%s\n' "\${TMUX_TEST_UPDATED_AT:-}"
                ;;
        esac
        ;;
    display-message)
        if [[ "\$*" == *"#{pane_current_command}"* ]]; then
            printf '%s\n' "\${TMUX_TEST_CURRENT_COMMAND:-zsh}"
            exit 0
        fi
        if [[ "\$*" == *"#{pane_current_path}"* ]]; then
            printf '%s\n' "\${TMUX_TEST_PANE_CURRENT_PATH:-}"
            exit 0
        fi
        if [[ "\$*" == *"#{session_id}"* ]]; then
            printf '%s\n' "\${TMUX_TEST_SESSION_ID:-\\$1}"
            exit 0
        fi
        exit 1
        ;;
    display-popup|split-window|new-window)
        exit 0
        ;;
    *)
        printf 'unexpected tmux command: %s\n' "\$cmd" >&2
        exit 1
        ;;
esac
EOF
    chmod +x "$wrapper_path"
}

run_tmux_open() {
    local wrapper_dir="$1"
    shift

    PATH="${wrapper_dir}:$PATH" "$TMUX_OPEN" "$@"
}

test_uses_valid_preferred_cwd_for_popup() {
    local wrapper_dir
    local tmux_log
    local preferred_cwd
    local fallback_cwd

    wrapper_dir="$(mktemp -d /tmp/tmux-open-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-open-log.XXXXXX)"
    preferred_cwd="$(mktemp -d /tmp/tmux-open-preferred.XXXXXX)"
    fallback_cwd="$(mktemp -d /tmp/tmux-open-fallback.XXXXXX)"
    write_tmux_wrapper "${wrapper_dir}/tmux" "$tmux_log"

    TMUX_TEST_PREFERRED_CWD="$preferred_cwd" \
        TMUX_TEST_OWNER="claude" \
        TMUX_TEST_CURRENT_COMMAND="claude" \
        TMUX_TEST_PANE_CURRENT_PATH="$fallback_cwd" \
        run_tmux_open "$wrapper_dir" popup-lazygit "%1"

    grep -F "display-popup -d ${preferred_cwd} -xC -yC -w 85% -h 85% -E lazygit" "$tmux_log" >/dev/null ||
        fail "expected popup-lazygit to use preferred cwd"

    rm -rf "$wrapper_dir" "$tmux_log" "$preferred_cwd" "$fallback_cwd"
}

test_falls_back_when_preferred_cwd_is_missing() {
    local wrapper_dir
    local tmux_log
    local missing_cwd
    local fallback_cwd

    wrapper_dir="$(mktemp -d /tmp/tmux-open-missing-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-open-missing-log.XXXXXX)"
    missing_cwd="/tmp/tmux-open-missing-not-created"
    fallback_cwd="$(mktemp -d /tmp/tmux-open-missing-fallback.XXXXXX)"
    write_tmux_wrapper "${wrapper_dir}/tmux" "$tmux_log"

    TMUX_TEST_PREFERRED_CWD="$missing_cwd" \
        TMUX_TEST_OWNER="claude" \
        TMUX_TEST_CURRENT_COMMAND="claude" \
        TMUX_TEST_PANE_CURRENT_PATH="$fallback_cwd" \
        run_tmux_open "$wrapper_dir" split-h "%1"

    grep -F "split-window -h -t %1 -c ${fallback_cwd}" "$tmux_log" >/dev/null ||
        fail "expected split-h to fall back to pane_current_path"

    rm -rf "$wrapper_dir" "$tmux_log" "$fallback_cwd"
}

test_falls_back_when_owner_mismatches() {
    local wrapper_dir
    local tmux_log
    local preferred_cwd
    local fallback_cwd

    wrapper_dir="$(mktemp -d /tmp/tmux-open-owner-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-open-owner-log.XXXXXX)"
    preferred_cwd="$(mktemp -d /tmp/tmux-open-owner-preferred.XXXXXX)"
    fallback_cwd="$(mktemp -d /tmp/tmux-open-owner-fallback.XXXXXX)"
    write_tmux_wrapper "${wrapper_dir}/tmux" "$tmux_log"

    TMUX_TEST_PREFERRED_CWD="$preferred_cwd" \
        TMUX_TEST_OWNER="claude" \
        TMUX_TEST_CURRENT_COMMAND="zsh" \
        TMUX_TEST_PANE_CURRENT_PATH="$fallback_cwd" \
        TMUX_TEST_SESSION_ID="\$9" \
        run_tmux_open "$wrapper_dir" new-window "%1"

    grep -F "new-window -t \$9 -c ${fallback_cwd}" "$tmux_log" >/dev/null ||
        fail "expected new-window to fall back on owner mismatch"

    rm -rf "$wrapper_dir" "$tmux_log" "$preferred_cwd" "$fallback_cwd"
}

test_falls_back_when_preferred_cwd_is_stale() {
    local wrapper_dir
    local tmux_log
    local preferred_cwd
    local fallback_cwd

    wrapper_dir="$(mktemp -d /tmp/tmux-open-stale-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-open-stale-log.XXXXXX)"
    preferred_cwd="$(mktemp -d /tmp/tmux-open-stale-preferred.XXXXXX)"
    fallback_cwd="$(mktemp -d /tmp/tmux-open-stale-fallback.XXXXXX)"
    write_tmux_wrapper "${wrapper_dir}/tmux" "$tmux_log"

    TMUX_TEST_PREFERRED_CWD="$preferred_cwd" \
        TMUX_TEST_OWNER="claude" \
        TMUX_TEST_CURRENT_COMMAND="claude" \
        TMUX_TEST_UPDATED_AT="1" \
        TMUX_OPEN_MAX_AGE_SECONDS="1" \
        TMUX_TEST_PANE_CURRENT_PATH="$fallback_cwd" \
        run_tmux_open "$wrapper_dir" split-v "%1"

    grep -F "split-window -v -t %1 -c ${fallback_cwd}" "$tmux_log" >/dev/null ||
        fail "expected split-v to fall back on stale preferred cwd"

    rm -rf "$wrapper_dir" "$tmux_log" "$preferred_cwd" "$fallback_cwd"
}

test_opens_lazygit_in_bottom_pane() {
    local wrapper_dir
    local tmux_log
    local preferred_cwd
    local fallback_cwd

    wrapper_dir="$(mktemp -d /tmp/tmux-open-lazygit-pane-wrapper.XXXXXX)"
    tmux_log="$(mktemp /tmp/tmux-open-lazygit-pane-log.XXXXXX)"
    preferred_cwd="$(mktemp -d /tmp/tmux-open-lazygit-pane-preferred.XXXXXX)"
    fallback_cwd="$(mktemp -d /tmp/tmux-open-lazygit-pane-fallback.XXXXXX)"
    write_tmux_wrapper "${wrapper_dir}/tmux" "$tmux_log"

    TMUX_TEST_PREFERRED_CWD="$preferred_cwd" \
        TMUX_TEST_OWNER="claude" \
        TMUX_TEST_CURRENT_COMMAND="claude" \
        TMUX_TEST_PANE_CURRENT_PATH="$fallback_cwd" \
        run_tmux_open "$wrapper_dir" split-v-lazygit "%1"

    grep -F "split-window -v -t %1 -c ${preferred_cwd} lazygit" "$tmux_log" >/dev/null ||
        fail "expected split-v-lazygit to open lazygit below from preferred cwd"

    rm -rf "$wrapper_dir" "$tmux_log" "$preferred_cwd" "$fallback_cwd"
}

main() {
    step "Running tmux-open tests"
    test_uses_valid_preferred_cwd_for_popup
    ok "uses valid preferred cwd for lazygit popup"
    test_falls_back_when_preferred_cwd_is_missing
    ok "falls back when preferred cwd is missing"
    test_falls_back_when_owner_mismatches
    ok "falls back when owner mismatches"
    test_falls_back_when_preferred_cwd_is_stale
    ok "falls back when preferred cwd is stale"
    test_opens_lazygit_in_bottom_pane
    ok "opens lazygit in a bottom pane"
}

main "$@"
