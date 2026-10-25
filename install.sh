#!/bin/zsh

set -e
set -o pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
SKIP_CONFIRMATION=0
RUN_BREW=0
RUN_LINK=0
RUN_MISE=0
RUN_CLAUDE=0
FULL_INSTALL=0
HAS_TARGET=0

UI_HELPERS="${DOTFILES_DIR}/scripts/lib/ui.sh"
. "$UI_HELPERS"

usage() {
    cat <<'EOF'
Usage: ./install.sh [--skip-confirmation] [TARGET...]

Targets:
  all                  Run every installation target (default)
  brew                 Install Homebrew if needed and apply Brewfile
  link                 Link all dotfile packages with GNU Stow
  mise                 Install tools managed by mise
  claude               Install Claude Code if needed

Options:
  --skip-confirmation    Do not prompt before running official remote installer scripts

Examples:
  ./install.sh
  ./install.sh link
  ./install.sh brew mise
EOF
}

die() {
    warn "$*"
    exit 1
}

brew_executable() {
    local candidate

    if command -v brew &> /dev/null; then
        command -v brew
        return 0
    fi

    for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$candidate" ]; then
            printf "%s\n" "$candidate"
            return 0
        fi
    done

    return 1
}

load_brew_shellenv() {
    local brew_bin

    brew_bin="$(brew_executable)" || {
        warn "Homebrew executable not found after installation"
        return 1
    }
    eval "$("$brew_bin" shellenv)"
}

select_all_targets() {
    RUN_BREW=1
    RUN_LINK=1
    RUN_MISE=1
    RUN_CLAUDE=1
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --skip-confirmation)
                SKIP_CONFIRMATION=1
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            all)
                select_all_targets
                FULL_INSTALL=1
                HAS_TARGET=1
                shift
                ;;
            brew)
                RUN_BREW=1
                HAS_TARGET=1
                shift
                ;;
            link)
                RUN_LINK=1
                HAS_TARGET=1
                shift
                ;;
            mise)
                RUN_MISE=1
                HAS_TARGET=1
                shift
                ;;
            claude)
                RUN_CLAUDE=1
                HAS_TARGET=1
                shift
                ;;
            *)
                die "Unknown target or option: $1 (expected: all, brew, link, mise, or claude)"
                ;;
        esac
    done

    if [ "$HAS_TARGET" -eq 0 ]; then
        select_all_targets
        FULL_INSTALL=1
    fi
}

print_selected_targets() {
    local -a targets

    if [ "$FULL_INSTALL" -eq 1 ]; then
        note "Targets: all"
        return
    fi

    targets=()
    if [ "$RUN_BREW" -eq 1 ]; then
        targets+=("brew")
    fi
    if [ "$RUN_LINK" -eq 1 ]; then
        targets+=("link")
    fi
    if [ "$RUN_MISE" -eq 1 ]; then
        targets+=("mise")
    fi
    if [ "$RUN_CLAUDE" -eq 1 ]; then
        targets+=("claude")
    fi

    note "Targets: ${targets[*]}"
}

confirm_remote_installer() {
    local name="$1"
    local url="$2"
    local answer

    if [ "$SKIP_CONFIRMATION" -eq 1 ]; then
        return 0
    fi

    note "About to run the official ${name} installer script:"
    printf "  %s\n" "$url"
    printf "Continue? [y/N] "
    read -r answer

    case "$answer" in
        y|Y|yes|YES)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

link_dotfiles() {
    step "Linking dotfiles with GNU Stow"

    local -a packages
    local package_dir

    if ! command -v stow &> /dev/null; then
        warn "stow not found; install Homebrew packages then rerun"
        return 1
    fi

    packages=()
    for package_dir in "${DOTFILES_DIR}"/packages/*(/N); do
        packages+=("${package_dir:t}")
    done

    if [ ${#packages[@]} -eq 0 ]; then
        warn "No packages found"
        return 1
    fi

    note "Packages: ${packages[*]}"
    if stow --no-folding --dir="${DOTFILES_DIR}/packages" --target="${HOME}" "${packages[@]}"; then
        ok "Linked dotfiles"
    else
        warn "stow failed; resolve conflicts and rerun"
        return 1
    fi
}

install_brew() {
    step "Checking Homebrew"
    if brew_executable >/dev/null; then
        skip "Homebrew already installed"
        return
    fi

    if ! confirm_remote_installer "Homebrew" "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"; then
        die "Homebrew install cancelled"
    fi

    if ! curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash; then
        warn "Homebrew install failed; check network/CLT and rerun"
        return 1
    fi
}

install_brew_packages() {
    step "Installing Homebrew packages"
    if ! brew bundle -v --file="${DOTFILES_DIR}/Brewfile"; then
        warn "brew bundle failed; fix Brewfile or network and rerun"
        return 1
    fi
}

install_mise_tools() {
    step "Installing mise tools"
    if ! command -v mise &> /dev/null; then
        warn "mise not found; install with 'brew install mise' then rerun"
        return 1
    fi

    eval "$(mise activate zsh)"
    mise install
}

install_claude_code() {
    step "Installing Claude Code"

    if command -v claude &> /dev/null; then
        skip "Claude Code already installed"
        return
    fi

    if ! confirm_remote_installer "Claude Code" "https://claude.ai/install.sh"; then
        die "Claude Code install cancelled"
    fi

    if ! curl -fsSL https://claude.ai/install.sh | bash; then
        warn "Claude Code install failed; check network and rerun"
        return 1
    fi

    ok "Installed Claude Code"
}

print_manual_setup_reminders() {
    echo ""
    section_line
    echo "${BOLD}Manual setup reminders${RESET}"
    echo ""
    echo "Homebrew apps/tools:"
    echo "  - Complete any first-run permissions or in-app setup"
    echo ""
    echo "Manual apps:"
    echo "  - Logi Tune: install manually; it is not managed by Homebrew here"
    echo ""
    echo "AeroSpace:"
    echo "  - Grant Accessibility permission in System Settings -> Privacy & Security -> Accessibility"
    echo "  - Run this command for multi-monitor support:"
    echo "    defaults write com.apple.spaces spans-displays -bool true && killall SystemUIServer"
    echo "  - Reload config with alt-shift-; then esc"
    echo ""
    echo "Claude Code settings:"
    echo "  - Add machine-specific JSON files if needed:"
    echo "    ~/.claude/_settings-source/*.json"
    echo "  - Generate settings after that:"
    echo "    dotfiles claude-settings"
    echo "Claude Code plugins:"
    echo "  - Reinstall plugins from /plugins"
    echo ""
    echo "pfw (Point-Free Way CLI):"
    echo "  - Follow https://github.com/pointfreeco/pfw"
    echo ""
    echo "macOS settings:"
    echo "  - Mission Control: Desktop & Dock -> disable Automatically rearrange Spaces based on most recent use"
    echo "  - Trackpad: Trackpad -> enable Tap to click"
    echo "  - Trackpad: Accessibility -> Pointer Control -> Trackpad Options... -> enable dragging and choose Three Finger Drag"
    section_line
}

main() {
    local border="${CYAN}${LINE_EQUAL}${RESET}"

    parse_args "$@"
    printf "%s\n" "$border"
    echo "${BOLD}${CYAN}🌟 Starting dotfiles installation${RESET}"
    printf "%s\n\n" "$border"
    print_selected_targets

    if [ "$RUN_BREW" -eq 1 ]; then
        install_brew
        load_brew_shellenv
        install_brew_packages
    fi
    if [ "$RUN_LINK" -eq 1 ]; then
        link_dotfiles
    fi
    if [ "$RUN_MISE" -eq 1 ]; then
        install_mise_tools
    fi
    if [ "$RUN_CLAUDE" -eq 1 ]; then
        install_claude_code
    fi

    echo ""
    if [ "$FULL_INSTALL" -eq 1 ]; then
        echo "${GREEN}🎉 Installation complete!${RESET}"
        echo "Please restart your terminal or run 'exec zsh' to apply the new setup."
        print_manual_setup_reminders
    else
        echo "${GREEN}🎉 Selected installation tasks complete!${RESET}"
    fi
}

main "$@"
