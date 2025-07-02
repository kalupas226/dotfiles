#!/bin/zsh

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_HOME="${HOME}/.config"

install_brew() {
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash
    else
        echo "Homebrew already installed"
    fi
}

install_mise() {
    if ! command -v mise &> /dev/null; then
        echo "Installing mise..."
        curl https://mise.run | sh
        mkdir -p ~/.local/bin
        if ! grep -q "mise activate" ~/.zshrc; then
            echo 'eval "$$(~/.local/bin/mise activate zsh)"' >> ~/.zshrc
        fi
    else
        echo "mise already installed"
    fi
}

install_brew_packages() {
    echo "Installing Homebrew packages..."
    brew bundle -v --file="${DOTFILES_DIR}/Brewfile"
}

install_node() {
    echo "Installing Node.js via mise..."
    source ~/.zshrc && mise use --global node@latest
}

install_npm_packages() {
    echo "Installing global npm packages..."
    if [ -f "${DOTFILES_DIR}/npmfile" ]; then
        while read -r package; do
            if [ -n "$package" ] && [ "${package#\#}" = "$package" ]; then
                echo "Installing $package..."
                npm install -g "$package"
            fi
        done < "${DOTFILES_DIR}/npmfile"
    else
        echo "npmfile not found, skipping npm package installation"
    fi
}


link_dotfiles() {
    echo "Linking dotfiles..."
    
    for package_dir in "${DOTFILES_DIR}"/packages/*/; do
        package_name=$(basename "${package_dir}")
        echo "Processing package: ${package_name}"
        
        # Find all files and directories starting with . in the package directory
        find "${package_dir}" -name ".*" -type f | while read -r source_file; do
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
        
        # Handle .config directories
        if [ -d "${package_dir}.config" ]; then
            mkdir -p "${CONFIG_HOME}"
            find "${package_dir}.config" -type f | while read -r config_file; do
                # Calculate relative path from .config directory
                relative_path="${config_file#${package_dir}.config/}"
                target_file="${CONFIG_HOME}/${relative_path}"
                target_dir=$(dirname "${target_file}")
                
                # Create target directory if it doesn't exist
                mkdir -p "${target_dir}"
                
                # Create symlink
                ln -sf "${config_file}" "${target_file}"
                echo "  Linked config: ${relative_path}"
            done
        fi
    done
}

main() {
    echo "Starting dotfiles installation..."
    
    install_brew
    install_mise
    install_brew_packages
    install_node
    install_npm_packages
    link_dotfiles
    
    echo "Installation complete!"
}

main "$@"
