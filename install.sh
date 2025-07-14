#!/bin/zsh

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

link_dotfiles() {
    echo "Linking dotfiles..."
    
    for package_dir in "${DOTFILES_DIR}"/packages/*/; do
        package_name=$(basename "${package_dir}")
        echo "Processing package: ${package_name}"
        
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
            echo "  Linked: ${relative_path}"
        done
    done
}

install_brew() {
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash
    else
        echo "Homebrew already installed"
    fi
}

install_brew_packages() {
    echo "Installing Homebrew packages..."
    brew bundle -v --file="${DOTFILES_DIR}/Brewfile"
}

install_mise() {
    if ! command -v mise &> /dev/null; then
        echo "Installing mise..."
        curl https://mise.run | sh
    else
        echo "mise already installed"
    fi
}

install_mise_tools() {
    echo "Installing mise tools..."
    eval "$(~/.local/bin/mise activate zsh)"
    ~/.local/bin/mise install 
}

main() {
    echo "Starting dotfiles installation..."
    
    link_dotfiles
    install_brew
    install_brew_packages
    install_mise
    install_mise_tools
    
    echo "Installation complete!"
    echo ""
    echo "Please restart your terminal or run 'source ~/.zshrc' to apply the new settings."
}

main "$@"
