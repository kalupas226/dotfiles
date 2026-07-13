#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/ui.sh"

INSTALLER="${REPO_ROOT}/install.sh"

fail() {
    warn "$*"
    exit 1
}

make_mock_command() {
    local mock_bin="$1"
    local command="$2"

    cat > "${mock_bin}/${command}" <<'EOF'
#!/bin/sh
printf '%s' "$(basename "$0")" >> "$INSTALL_LOG"
printf ' %s' "$@" >> "$INSTALL_LOG"
printf '\n' >> "$INSTALL_LOG"
EOF
    chmod +x "${mock_bin}/${command}"
}

make_curl_mock() {
    local mock_bin="$1"

    cat > "${mock_bin}/curl" <<'EOF'
#!/bin/sh
printf 'curl' >> "$INSTALL_LOG"
printf ' %s' "$@" >> "$INSTALL_LOG"
printf '\n' >> "$INSTALL_LOG"
printf 'exit 0\n'
EOF
    chmod +x "${mock_bin}/curl"
}

new_test_environment() {
    local tmpdir="$1"

    mkdir -p "${tmpdir}/home" "${tmpdir}/bin"
    : > "${tmpdir}/install.log"
    make_mock_command "${tmpdir}/bin" brew
    make_mock_command "${tmpdir}/bin" git
    make_mock_command "${tmpdir}/bin" mise
    make_mock_command "${tmpdir}/bin" stow
    make_curl_mock "${tmpdir}/bin"
}

run_installer() {
    local tmpdir="$1"
    shift

    HOME="${tmpdir}/home" \
        PATH="${tmpdir}/bin:/usr/bin:/bin" \
        INSTALL_LOG="${tmpdir}/install.log" \
        zsh "$INSTALLER" "$@"
}

test_link_runs_only_stow() {
    local tmpdir
    local log
    local output

    tmpdir="$(mktemp -d /tmp/dotfiles-install-link.XXXXXX)"
    new_test_environment "$tmpdir"

    output="$(run_installer "$tmpdir" link)"
    log="$(cat "${tmpdir}/install.log")"

    [[ "$log" == stow\ * ]] || fail "expected link target to run stow"
    [[ "$(wc -l < "${tmpdir}/install.log" | tr -d ' ')" == 1 ]] ||
        fail "expected link target to run no other installation commands"
    [[ "$output" != *"Manual setup reminders"* ]] ||
        fail "expected a partial installation to omit full-install reminders"

    rm -rf "$tmpdir"
}

test_multiple_targets_run_in_installation_order() {
    local tmpdir
    local expected
    local log

    tmpdir="$(mktemp -d /tmp/dotfiles-install-multiple.XXXXXX)"
    new_test_environment "$tmpdir"

    run_installer "$tmpdir" mise brew >/dev/null
    log="$(cat "${tmpdir}/install.log")"
    expected="$(printf '%s\n' \
        'brew shellenv' \
        "brew bundle -v --file=${REPO_ROOT}/Brewfile" \
        'mise activate zsh' \
        'mise install')"

    [[ "$log" == "$expected" ]] ||
        fail "expected selected targets to run once in canonical installation order"

    rm -rf "$tmpdir"
}

test_no_target_runs_full_installation() {
    local tmpdir
    local output
    local log

    tmpdir="$(mktemp -d /tmp/dotfiles-install-all.XXXXXX)"
    new_test_environment "$tmpdir"

    output="$(run_installer "$tmpdir" --skip-confirmation)"
    log="$(cat "${tmpdir}/install.log")"

    [[ "$log" == *$'brew shellenv\nbrew bundle '* ]] ||
        fail "expected full installation to run the brew target first"
    [[ "$log" == *$'\nstow '* ]] || fail "expected full installation to run the link target"
    [[ "$log" == *$'\ngit clone '* ]] || fail "expected full installation to run the tpm target"
    [[ "$log" == *$'\nmise activate zsh\nmise install'* ]] ||
        fail "expected full installation to run the mise target"
    [[ "$log" == *$'\ncurl -fsSL https://claude.ai/install.sh' ]] ||
        fail "expected full installation to run the claude target"
    [[ "$output" == *"Manual setup reminders"* ]] ||
        fail "expected full installation to print manual setup reminders"

    rm -rf "$tmpdir"
}

test_unknown_target_fails_before_installing() {
    local tmpdir
    local output

    tmpdir="$(mktemp -d /tmp/dotfiles-install-unknown.XXXXXX)"
    new_test_environment "$tmpdir"

    if output="$(run_installer "$tmpdir" unknown 2>&1)"; then
        fail "expected an unknown target to fail"
    fi

    [[ "$output" == *"Unknown target or option: unknown"* ]] ||
        fail "expected an unknown target error"
    [[ ! -s "${tmpdir}/install.log" ]] ||
        fail "expected an unknown target to fail before installation"

    rm -rf "$tmpdir"
}

main() {
    step "Running install target tests"
    test_link_runs_only_stow
    ok "runs only the selected link target"
    test_multiple_targets_run_in_installation_order
    ok "runs multiple targets in installation order"
    test_no_target_runs_full_installation
    ok "preserves the full installation default"
    test_unknown_target_fails_before_installing
    ok "rejects unknown targets before installation"
}

main "$@"
