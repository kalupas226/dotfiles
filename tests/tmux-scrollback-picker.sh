#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/ui.sh"

TMUX_SCROLLBACK_PICKER="${REPO_ROOT}/packages/tmux/.local/libexec/tmux/scrollback-picker"

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
    capture-pane)
        printf '%b' "\${TMUX_SCROLLBACK_PICKER_TEST_CAPTURE:-}"
        ;;
    display-message|display-popup|set-buffer|paste-buffer)
        ;;
    *)
        printf 'unexpected tmux command: %s\n' "\$cmd" >&2
        exit 1
        ;;
esac
EOF
    chmod +x "$wrapper_path"
}

write_fzf_wrapper() {
    local wrapper_path="$1"
    local fzf_log="$2"
    local fzf_input="$3"

    cat >"$wrapper_path" <<EOF
#!/usr/bin/env bash
set -euo pipefail

printf 'fzf' >>"${fzf_log}"
for arg in "\$@"; do
    printf ' %s' "\$arg" >>"${fzf_log}"
done
printf '\n' >>"${fzf_log}"
cat >"${fzf_input}"

exit_code="\${TMUX_SCROLLBACK_PICKER_TEST_FZF_EXIT:-0}"
if [[ "\$exit_code" != "0" ]]; then
    exit "\$exit_code"
fi

printf '%b' "\${TMUX_SCROLLBACK_PICKER_TEST_FZF_OUTPUT:-}"
EOF
    chmod +x "$wrapper_path"
}

write_pbcopy_wrapper() {
    local wrapper_path="$1"
    local pbcopy_log="$2"

    cat >"$wrapper_path" <<EOF
#!/usr/bin/env bash
set -euo pipefail

cat >>"${pbcopy_log}"
EOF
    chmod +x "$wrapper_path"
}

write_open_wrapper() {
    local wrapper_path="$1"
    local open_log="$2"

    cat >"$wrapper_path" <<EOF
#!/usr/bin/env bash
set -euo pipefail

printf 'open' >>"${open_log}"
for arg in "\$@"; do
    printf ' %s' "\$arg" >>"${open_log}"
done
printf '\n' >>"${open_log}"
EOF
    chmod +x "$wrapper_path"
}

setup_wrappers() {
    local wrapper_dir="$1"
    local tmux_log="$2"
    local fzf_log="$3"
    local fzf_input="$4"
    local pbcopy_log="$5"
    local open_log="$6"

    write_tmux_wrapper "${wrapper_dir}/tmux" "$tmux_log"
    write_fzf_wrapper "${wrapper_dir}/fzf" "$fzf_log" "$fzf_input"
    write_pbcopy_wrapper "${wrapper_dir}/pbcopy" "$pbcopy_log"
    write_open_wrapper "${wrapper_dir}/open" "$open_log"
}

run_scrollback_picker() {
    local wrapper_dir="$1"
    shift

    PATH="${wrapper_dir}:$PATH" "$TMUX_SCROLLBACK_PICKER" "$@"
}

make_fixture() {
    local prefix="$1"
    local tmpdir="${TMPDIR:-/tmp}"

    WRAPPER_DIR="$(mktemp -d "${tmpdir%/}/tmux-scrollback-${prefix}-wrapper.XXXXXX")"
    TMUX_LOG="$(mktemp "${tmpdir%/}/tmux-scrollback-${prefix}-log.XXXXXX")"
    FZF_LOG="$(mktemp "${tmpdir%/}/tmux-scrollback-${prefix}-fzf-log.XXXXXX")"
    FZF_INPUT="$(mktemp "${tmpdir%/}/tmux-scrollback-${prefix}-fzf-input.XXXXXX")"
    PBCOPY_LOG="$(mktemp "${tmpdir%/}/tmux-scrollback-${prefix}-pbcopy-log.XXXXXX")"
    OPEN_LOG="$(mktemp "${tmpdir%/}/tmux-scrollback-${prefix}-open-log.XXXXXX")"
    setup_wrappers "$WRAPPER_DIR" "$TMUX_LOG" "$FZF_LOG" "$FZF_INPUT" "$PBCOPY_LOG" "$OPEN_LOG"
}

cleanup_fixture() {
    rm -rf "$WRAPPER_DIR" "$TMUX_LOG" "$FZF_LOG" "$FZF_INPUT" "$PBCOPY_LOG" "$OPEN_LOG"
}

test_opens_popup() {
    make_fixture "popup"

    run_scrollback_picker "$WRAPPER_DIR" "%1"

    grep -F "display-popup -t %1 -xC -yC -w 85% -h 85% -T  scrollback  -E " "$TMUX_LOG" >/dev/null ||
        fail "expected scrollback-picker to open a popup"
    grep -F -- "--pick" "$TMUX_LOG" >/dev/null ||
        fail "expected the popup command to re-enter pick mode"

    cleanup_fixture
}

test_pick_tokenizes_scrollback() {
    make_fixture "tokens"

    TMUX_SCROLLBACK_PICKER_TEST_CAPTURE=$'a b tiny (packages/tmux/.tmux.conf) visit https://example.com/docs.\nerror: build/Sources/App.swift:12\npackages/tmux/.tmux.conf\n' \
        TMUX_SCROLLBACK_PICKER_TEST_FZF_OUTPUT='' \
        run_scrollback_picker "$WRAPPER_DIR" --pick "%1"

    grep -F "capture-pane -p -J -t %1 -S -" "$TMUX_LOG" >/dev/null ||
        fail "expected the full scrollback of the source pane to be captured"
    [[ "$(head -n 1 "$FZF_INPUT")" == "packages/tmux/.tmux.conf" ]] ||
        fail "expected the most recent token first"
    [[ "$(grep -c -F -x "packages/tmux/.tmux.conf" "$FZF_INPUT")" == "1" ]] ||
        fail "expected duplicate tokens to be deduplicated"
    grep -F -x "https://example.com/docs" "$FZF_INPUT" >/dev/null ||
        fail "expected URLs to be listed without trailing punctuation"
    grep -F -x "build/Sources/App.swift:12" "$FZF_INPUT" >/dev/null ||
        fail "expected path:line tokens to keep their line numbers"
    if grep -F -x "tiny" "$FZF_INPUT" >/dev/null; then
        fail "expected short tokens to be filtered out"
    fi

    cleanup_fixture
}

test_pick_pastes_selection() {
    make_fixture "paste"

    TMUX_SCROLLBACK_PICKER_TEST_CAPTURE=$'first-token second-token\n' \
        TMUX_SCROLLBACK_PICKER_TEST_FZF_OUTPUT=$'\nfirst-token\nsecond-token\n' \
        run_scrollback_picker "$WRAPPER_DIR" --pick "%1"

    grep -F "set-buffer -b tmux-scrollback-picker -- first-token second-token" "$TMUX_LOG" >/dev/null ||
        fail "expected the selection to be joined into a buffer"
    grep -F "paste-buffer -t %1 -b tmux-scrollback-picker" "$TMUX_LOG" >/dev/null ||
        fail "expected the buffer to be pasted into the source pane"

    cleanup_fixture
}

test_pick_copies_to_clipboard() {
    make_fixture "copy"

    TMUX_SCROLLBACK_PICKER_TEST_CAPTURE=$'first-token second-token\n' \
        TMUX_SCROLLBACK_PICKER_TEST_FZF_OUTPUT=$'ctrl-y\nfirst-token\nsecond-token\n' \
        run_scrollback_picker "$WRAPPER_DIR" --pick "%1"

    grep -F "first-token second-token" "$PBCOPY_LOG" >/dev/null ||
        fail "expected the selection to be copied with pbcopy"
    if grep -F "paste-buffer" "$TMUX_LOG" >/dev/null; then
        fail "expected copy mode not to paste into the pane"
    fi

    cleanup_fixture
}

test_pick_opens_urls_only() {
    make_fixture "open"

    TMUX_SCROLLBACK_PICKER_TEST_CAPTURE=$'https://example.com/docs packages/tmux/.tmux.conf\n' \
        TMUX_SCROLLBACK_PICKER_TEST_FZF_OUTPUT=$'ctrl-o\nhttps://example.com/docs\npackages/tmux/.tmux.conf\n' \
        run_scrollback_picker "$WRAPPER_DIR" --pick "%1"

    grep -F -x "open https://example.com/docs" "$OPEN_LOG" >/dev/null ||
        fail "expected the selected URL to be opened"
    if grep -F "packages/tmux/.tmux.conf" "$OPEN_LOG" >/dev/null; then
        fail "expected non-URL selections not to be opened"
    fi
    grep -F "display-message -l -t %1 tmux/scrollback-picker: not a URL: packages/tmux/.tmux.conf" "$TMUX_LOG" >/dev/null ||
        fail "expected non-URL selections to be reported"

    cleanup_fixture
}

test_pick_cancel_does_nothing() {
    make_fixture "cancel"

    TMUX_SCROLLBACK_PICKER_TEST_CAPTURE=$'first-token second-token\n' \
        TMUX_SCROLLBACK_PICKER_TEST_FZF_EXIT=130 \
        run_scrollback_picker "$WRAPPER_DIR" --pick "%1"

    if grep -E "set-buffer|paste-buffer" "$TMUX_LOG" >/dev/null; then
        fail "expected picker cancellation not to paste"
    fi
    if [[ -s "$PBCOPY_LOG" || -s "$OPEN_LOG" ]]; then
        fail "expected picker cancellation not to copy or open"
    fi

    cleanup_fixture
}

test_pick_reports_empty_scrollback() {
    make_fixture "empty"

    TMUX_SCROLLBACK_PICKER_TEST_CAPTURE='' \
        run_scrollback_picker "$WRAPPER_DIR" --pick "%1"

    grep -F "display-message -l -t %1 tmux/scrollback-picker: no text in scrollback" "$TMUX_LOG" >/dev/null ||
        fail "expected empty scrollback to be reported"
    if grep -F "fzf" "$FZF_LOG" >/dev/null; then
        fail "expected fzf not to run for empty scrollback"
    fi

    cleanup_fixture
}

main() {
    step "Running tmux-scrollback-picker tests"
    test_opens_popup
    ok "opens popup for the active pane"
    test_pick_tokenizes_scrollback
    ok "tokenizes scrollback with recency, dedupe, and length filters"
    test_pick_pastes_selection
    ok "pastes the joined selection"
    test_pick_copies_to_clipboard
    ok "copies the selection to the clipboard"
    test_pick_opens_urls_only
    ok "opens URLs and reports non-URL selections"
    test_pick_cancel_does_nothing
    ok "cancels without side effects"
    test_pick_reports_empty_scrollback
    ok "reports empty scrollback"
}

main "$@"
