# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Architecture

This is a personal macOS dotfiles repository organized using a package-based architecture. Each package contains configuration files in their expected directory structure and gets automatically symlinked to the home directory.

### Package Structure
- **packages/**: Contains individual application configurations
  - `claude/`: Claude Code settings and configurations
  - `git/`: Git configuration files
  - `mise/`: Development environment manager configuration
  - `nvim/`: Neovim configuration
  - `sheldon/`: Shell plugin manager configuration
  - `starship/`: Starship prompt configuration
  - `tig/`: Git browser configuration
  - `tmux/`: Terminal multiplexer configuration
  - `wezterm/`: Terminal emulator configuration
  - `zsh/`: Zsh shell configuration

### Key Configuration Files
- **Brewfile**: Homebrew package definitions for CLI tools and GUI applications
- **install.sh**: Main installation script with custom symlinking logic
- **packages/claude/.claude/settings.json**: Claude Code security permissions and hooks configuration

## Installation and Setup Commands

### Initial Setup
```bash
# Clone and install entire dotfiles setup
git clone https://github.com/kalupas226/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

### Individual Package Management
```bash
# Reinstall Homebrew packages
brew bundle -v --file=Brewfile

# Install mise tools
mise install

# Relink dotfiles (after making changes)
# The install.sh script handles this automatically
```

### Neovim Configuration
- Configuration located in `packages/nvim/`
- Automatically symlinked to `~/.config/nvim/`
- Uses modern Neovim plugin ecosystem

### Claude Code Integration
- Settings: Located in `packages/claude/.claude/settings.json`
- Security: Configured to block dangerous operations while allowing development tasks
- Hooks: Terminal notifications configured for task completion and response finish
- Permissions: Additional directories include `/Users/kalupas226/Development`

## Development Workflow

### Making Configuration Changes
1. Edit files in the appropriate `packages/` directory
2. Changes are automatically reflected via symlinks
3. For Neovim: restart or `:source` to reload configuration
4. For shell configs: restart terminal or `source ~/.zshrc`

### Adding New Packages
1. Create new directory under `packages/`
2. Add configuration files in their expected structure
3. Run `./install.sh` to create symlinks

### Security Considerations
- Claude Code permissions are configured in `packages/claude/.claude/settings.json`
- Dangerous operations (rm -rf /, sudo, network commands) are blocked
- File operations and development commands are permitted
- Terminal notifications are configured for task completion