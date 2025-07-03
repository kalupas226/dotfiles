# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Architecture

This is a personal macOS dotfiles repository organized using a package-based architecture. Each package contains configuration files in their expected directory structure and gets automatically symlinked to the home directory.

### Package Structure
- **packages/**: Contains individual application configurations
  - `git/`: Git configuration files
  - `starship/`: Starship prompt configuration
  - `tig/`: Git browser configuration
  - `tmux/`: Terminal multiplexer configuration
  - `nvim/`: Neovim configuration with lazy.nvim plugin manager
  - `wezterm/`: Terminal emulator configuration
  - `zsh/`: Zsh shell configuration
  - `claude/`: Claude Code settings and configurations

### Key Configuration Files
- **Brewfile**: Homebrew package definitions for CLI tools and GUI applications
- **npmfile**: Global npm packages (claude-code, bash-language-server, etc.)
- **install.sh**: Main installation script with custom symlinking logic
- **settings.json**: Claude Code security permissions and hooks configuration

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

# Install global npm packages
npm install -g $(cat npmfile)

# Relink dotfiles (after making changes)
# The install.sh script handles this automatically
```

### Neovim Configuration
- Uses **lazy.nvim** as plugin manager with automatic bootstrapping
- LSP configured for: Bash, Swift, JSON, JavaScript/TypeScript
- Includes: nvim-cmp (completion), telescope (fuzzy finder), nvim-tree (file explorer)
- Plugin configurations are in `packages/nvim/.config/nvim/lua/plugins/`

### Claude Code Integration
- Plugin: `claude-code.nvim` installed in Neovim configuration
- Settings: Located in `packages/claude/.claude/settings.json`
- Security: Configured to block dangerous operations while allowing development tasks
- Keymaps: `<C-,>` to toggle Claude Code terminal, `<leader>cC` for continue mode

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