#!/bin/zsh

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
SKIP_CONFIRMATION=0

UI_HELPERS="${DOTFILES_DIR}/scripts/lib/ui.sh"
. "$UI_HELPERS"

usage() {
    cat <<'EOF'
Usage: ./install.sh [--skip-confirmation]

Options:
  --skip-confirmation    Do not prompt before running official remote installer scripts
EOF
}

die() {
    warn "$*"
    exit 1
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
            *)
                die "Unknown option: $1"
                ;;
        esac
    done
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

install_tpm() {
    step "Installing TPM (tmux plugin manager)"

    if [ -d "${HOME}/.tmux/plugins/tpm" ]; then
        skip "TPM already installed"
        return
    fi

    if ! command -v git &> /dev/null; then
        warn "git not found; install git then rerun"
        return 1
    fi

    if git clone https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"; then
        ok "Installed TPM"
    else
        warn "TPM install failed; check network and rerun"
        return 1
    fi
}

install_brew() {
    step "Checking Homebrew"
    if command -v brew &> /dev/null; then
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

    if ! curl -fsSL https://claude.ai/install.sh | sh; then
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
    echo "tmux plugins:"
    echo "  - Open tmux and run prefix + I"
    echo ""
    echo "Neovim plugins:"
    echo "  - Open Neovim and run :Lazy sync"
    echo ""
    echo "Claude Code settings:"
    echo "  - Add machine-specific JSON files if needed:"
    echo "    ~/.claude/_settings-source/*.json"
    echo "  - Generate settings after that:"
    echo "    dotfiles claude-settings"
    echo "Claude Code plugins:"
    echo "  - Reinstall plugins from /plugins"
    echo ""
    echo "Other manual setup:"
    echo "  - See this repository's README.md for macOS settings, app permissions, and tool-specific setup"
    section_line
}

main() {
    local border="${CYAN}${LINE_EQUAL}${RESET}"

    parse_args "$@"
    printf "%s\n" "$border"
    echo "${BOLD}${CYAN}🌟 Starting dotfiles installation${RESET}"
    printf "%s\n\n" "$border"

    install_brew
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null
    install_brew_packages
    link_dotfiles
    install_tpm
    install_mise_tools
    install_claude_code
    
    echo ""
    echo "${GREEN}🎉 Installation complete!${RESET}"
    echo "Please restart your terminal or run 'exec zsh' to apply the new setup."
    print_manual_setup_reminders
}

main "$@"
