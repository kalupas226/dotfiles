# dotfiles

My personal macOS dotfiles organized by packages with automated installation.

## Installation

### Prerequisites (macOS)
```bash
sudo softwareupdate -i -a
xcode-select --install
```

### Quick Install
Default location is `~/.dotfiles`. Clone and run:

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
- **Dotfiles** - Automatically symlinked to your home directory

Restart your terminal or run `source ~/.zshrc` to load the new configuration.

### Using mise tasks
- Install/link everything (runs `install.sh` under the hood):  
  `mise run dotfiles:install`
- Check for updates (brew/mise/neovim/sheldon):  
  `mise run dotfiles:check-updates`

Custom location: set `DOTFILES_DIR` before running tasks, e.g.  
`DOTFILES_DIR=/path/to/dotfiles mise run dotfiles:install`

## Maintenance

- Node: pinned via mise in `packages/mise/.config/mise/config.toml`
- npm CLIs: prefer project-local `devDependencies` or `npm dlx`/`npx`; only keep truly global needs in `packages/npm/global-packages.txt` and `install.sh` will install them
- Updates check (one-shot, no writes): `mise run dotfiles:check-updates`
  - Homebrew (`brew update --quiet` + `brew outdated`)
  - mise tools (`mise outdated`)
  - sheldon plugins (pinned `rev` vs latest tags)
- If `brew bundle` or `mise install` fails mid-run, fix the cause then rerun `mise run dotfiles:install`.

## Repository Structure

This repository uses a package-based organization:

```
packages/
├── claude/     # Claude Code settings and configurations
├── git/        # Git configuration
├── npm/        # npm CLI defaults
├── mise/       # Development environment manager configuration
├── nvim/       # Neovim configuration
├── sheldon/    # Shell plugin manager configuration
├── starship/   # Starship prompt configuration  
├── tig/        # Git browser configuration
├── tmux/       # Terminal multiplexer configuration
├── wezterm/    # Terminal emulator configuration
└── zsh/        # Zsh shell configuration
```

Each package contains dotfiles in their expected directory structure. The installation script automatically creates symlinks from package files to their target locations in your home directory.

## Configuration Files

- **packages/mise/.config/mise.toml** - tool pins and mise tasks (`dotfiles:install`, `dotfiles:check-updates`)
- **Brewfile** - Homebrew package definitions
- **install.sh** - Main installation script with custom symlinking logic
- **scripts/** - helper scripts (e.g. `check-updates.sh`, `lib/ui.sh`)
- **packages/** - Individual application configurations
