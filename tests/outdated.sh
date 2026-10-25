#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/ui.sh"

OUTDATED="${REPO_ROOT}/scripts/outdated.sh"
BREW_OUTDATED="${REPO_ROOT}/scripts/outdated/brew-outdated.sh"
MISE_OUTDATED="${REPO_ROOT}/scripts/outdated/mise-outdated.sh"

fail() {
    warn "$*"
    exit 1
}

create_fake_commands() {
    local wrapper_dir="$1"

    mkdir -p "$wrapper_dir"

    cat > "${wrapper_dir}/brew" <<'EOF'
#!/usr/bin/env bash
if [[ -n "${FAKE_COMMAND_LOG:-}" ]]; then
    printf 'brew %s\n' "$*" >> "$FAKE_COMMAND_LOG"
fi
case "${1:-}" in
    update) exit "${FAKE_BREW_UPDATE_STATUS:-0}" ;;
    outdated) exit "${FAKE_BREW_OUTDATED_STATUS:-0}" ;;
esac
exit 0
EOF

    cat > "${wrapper_dir}/mise" <<'EOF'
#!/usr/bin/env bash
exit "${FAKE_MISE_STATUS:-0}"
EOF

    chmod +x "${wrapper_dir}/brew" "${wrapper_dir}/mise"
}

test_dispatcher_propagates_brew_failure() {
    local tmpdir
    local wrapper_dir

    tmpdir="$(mktemp -d /tmp/dotfiles-outdated-dispatcher.XXXXXX)"
    wrapper_dir="${tmpdir}/bin"
    create_fake_commands "$wrapper_dir"

    if PATH="${wrapper_dir}:/usr/bin:/bin" FAKE_BREW_OUTDATED_STATUS=1 bash "$OUTDATED" brew >/dev/null 2>&1; then
        fail "expected outdated dispatcher to propagate brew failure"
    fi

    PATH="${wrapper_dir}:/usr/bin:/bin" FAKE_BREW_OUTDATED_STATUS=0 bash "$OUTDATED" brew >/dev/null ||
        fail "expected outdated dispatcher to succeed when brew succeeds"

    rm -rf "$tmpdir"
}

test_brew_refresh_failure_still_checks_outdated() {
    local tmpdir
    local wrapper_dir
    local command_log

    tmpdir="$(mktemp -d /tmp/dotfiles-outdated-brew.XXXXXX)"
    wrapper_dir="${tmpdir}/bin"
    command_log="${tmpdir}/commands.log"
    create_fake_commands "$wrapper_dir"

    if PATH="${wrapper_dir}:/usr/bin:/bin" \
        FAKE_COMMAND_LOG="$command_log" \
        FAKE_BREW_UPDATE_STATUS=1 \
        DOTFILES_OUTDATED_REFRESH=1 \
        bash "$BREW_OUTDATED" >/dev/null 2>&1; then
        fail "expected brew refresh failure to return non-zero"
    fi

    grep -F "brew update --quiet" "$command_log" >/dev/null ||
        fail "expected brew refresh to run"
    grep -F "brew outdated" "$command_log" >/dev/null ||
        fail "expected brew outdated to run after refresh failure"

    rm -rf "$tmpdir"
}

test_mise_failure_returns_nonzero() {
    local tmpdir
    local wrapper_dir

    tmpdir="$(mktemp -d /tmp/dotfiles-outdated-mise.XXXXXX)"
    wrapper_dir="${tmpdir}/bin"
    create_fake_commands "$wrapper_dir"

    if PATH="${wrapper_dir}:/usr/bin:/bin" FAKE_MISE_STATUS=1 bash "$MISE_OUTDATED" >/dev/null 2>&1; then
        fail "expected mise failure to return non-zero"
    fi

    rm -rf "$tmpdir"
}

main() {
    step "Running outdated tests"
    test_dispatcher_propagates_brew_failure
    ok "propagates source failures through the dispatcher"
    test_brew_refresh_failure_still_checks_outdated
    ok "keeps checking brew after refresh failure"
    test_mise_failure_returns_nonzero
    ok "returns non-zero when mise fails"
}

main "$@"
