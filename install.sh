#!/bin/zsh

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

UI_HELPERS="${DOTFILES_DIR}/scripts/lib/ui.sh"
. "$UI_HELPERS"

link_dotfiles() {
    step "Linking dotfiles"
    
    local first_package=1
    for package_dir in "${DOTFILES_DIR}"/packages/*/; do
        if [ $first_package -eq 0 ]; then
            section_line
        fi
        first_package=0
        package_name=$(basename "${package_dir}")
        note "Package: ${package_name}"
        
        # Find all files starting with . or inside directories starting with .
        find "${package_dir}" \( -name ".*" -o -path "*/.*" \) -type f | while read -r source_file; do
            # Calculate relative path from package directory
            relative_path="${source_file#${package_dir}}"
            target_file="${HOME}/${relative_path}"
            target_dir=$(dirname "${target_file}")
            
            # Create target directory if it doesn't exist
            mkdir -p "${target_dir}"
            
            # Create symlink
            ln -sf "${source_file}" "${target_file}"
            ok "Linked ${relative_path}"
        done
    done
}

install_brew() {
    step "Checking Homebrew"
    if command -v brew &> /dev/null; then
        skip "Homebrew already installed"
        return
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

install_global_npm_packages() {
    step "Installing global npm CLIs"

    eval "$(mise activate zsh)"  # ensure mise-managed Node/npm is on PATH

    if ! command -v npm &> /dev/null; then
        warn "npm not found; install Node via mise first"
        return 1
    fi

    local list_file="${DOTFILES_DIR}/packages/npm/global-packages.txt"
    if [ ! -f "$list_file" ]; then
        skip "No global npm package list found"
        return
    fi

    while IFS= read -r pkg; do
        [ -z "$pkg" ] && continue
        case "$pkg" in
            \#*) continue ;;
        esac
        note "npm install -g ${pkg}"
        if ! npm install -g "$pkg"; then
            warn "Failed to install ${pkg}"
        fi
    done < "$list_file"
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

main() {
    local border="${CYAN}${LINE_EQUAL}${RESET}"
    printf "%s\n" "$border"
    echo "${BOLD}${CYAN}🌟 Starting dotfiles installation${RESET}"
    printf "%s\n\n" "$border"
    
    link_dotfiles
    install_tpm
    install_brew
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null
    install_brew_packages
    install_mise_tools
    install_global_npm_packages
    
    echo ""
    echo "${GREEN}🎉 Installation complete!${RESET}"
    echo "Please restart your terminal or run 'source ~/.zshrc' to apply the new setup."
}

main "$@"
