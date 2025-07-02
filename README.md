# dotfiles

My personal macOS dotfiles organized by packages with automated installation.

## Installation

### Prerequisites (macOS)
```bash
sudo softwareupdate -i -a
xcode-select --install
```

### Quick Install
Clone the repository and run the installation script:

```bash
git clone https://github.com/kalupas226/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

### What gets installed
- **Homebrew** - Package manager for macOS
- **mise** - Development environment manager
- **CLI tools** - bat, eza, fzf, ripgrep, starship, tig, neovim, etc.
- **GUI applications** - Arc, CleanShot, Wezterm, VSCode, etc.
- **Fonts** - Hack Nerd Font
- **Node.js** - Latest LTS version via mise
- **Global npm packages** - claude-code, bash-language-server, etc.
- **Dotfiles** - Automatically symlinked to your home directory

### Post-installation setup

To install additional language servers for NeoVim:

1. Open NeoVim nad install coc-marketplace: `:CocInstall coc-marketplace`
2. Browse and install language servers: `:CocList marketplace`

## Repository Structure

This repository uses a package-based organization:

```
packages/
├── git/        # Git configuration
├── starship/   # Starship prompt configuration  
├── tig/        # Git browser configuration
├── tmux/       # Terminal multiplexer configuration
├── nvim/       # Neovim configuration
├── wezterm/    # Terminal emulator configuration
└── zsh/        # Zsh shell configuration
```

Each package contains dotfiles in their expected directory structure. The installation script automatically creates symlinks from package files to their target locations in your home directory.

## Configuration Files

- **Brewfile** - Homebrew package definitions
- **npmfile** - Global npm package definitions (installed via `npm install -g`)
- **install.sh** - Main installation script with custom symlinking logic
- **packages/** - Individual application configurations

