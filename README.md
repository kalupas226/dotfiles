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
- **Node.js** - Pinned via mise
- **Dotfiles** - Automatically symlinked to your home directory

Restart your terminal or run `source ~/.zshrc` to load the new configuration.

### Post-install manual steps

Some tools require a one-time manual step after `install.sh`:

- **tmux plugins (TPM)**: open tmux and run `prefix + I` to install plugins (e.g. `vim-tmux-navigator`)
- **Neovim plugins (lazy.nvim)**: open Neovim and run `:Lazy sync`
- **Homebrew apps/tools**: some packages need first-run setup, permissions (e.g. macOS Security & Privacy), or in-app configuration—check each tool as needed
- **yabai**:
  - Grant **Accessibility** permission to the `yabai` binary in `System Settings → Privacy & Security → Accessibility`
  - Start the service: `brew services start yabai`
  - Restart after config changes: `yabai --restart-service`
  - Install guide (latest release): https://github.com/asmvik/yabai/wiki/Installing-yabai-(latest-release)
- **Logi Tune**: install manually (not managed by Homebrew in this repo). Reference: https://www.logitech.com/assets/66219/5/brio-500.pdf
- **macOS settings**: set these in System Settings (paths can vary by macOS version)
  - Mission Control: `Desktop & Dock` → disable "Automatically rearrange Spaces based on most recent use"
  - Trackpad: `Trackpad` → enable "Tap to click"
  - Trackpad: `Accessibility` → `Pointer Control` → `Trackpad Options...` → enable dragging and choose "Three Finger Drag"
  - Keyboard: `Keyboard` → `Keyboard Shortcuts...` → `Modifier Keys...` → set "Caps Lock" to "Control"

### Using mise tasks

- Install/link everything (runs `install.sh` under the hood):  
  `mise run dotfiles:install`
- Check for updates (brew/mise/npm/sheldon):  
  `mise run dotfiles:check-updates`

Tasks are defined in `packages/mise/.config/mise/config.toml`.

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
  - If you don't use mise tasks, run `./scripts/check-updates.sh`

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
├── yabai/      # Tiling window manager configuration
└── zsh/        # Zsh shell configuration
```

Each package contains dotfiles in their expected directory structure. The installation script automatically creates symlinks from package files to their target locations in your home directory.

## Configuration Files

- **packages/mise/.config/mise/config.toml** - tool pins and mise tasks (`dotfiles:install`, `dotfiles:check-updates`)
- **Brewfile** - Homebrew package definitions
- **install.sh** - Main installation script with custom symlinking logic
- **scripts/** - helper scripts (e.g. `check-updates.sh`, `lib/ui.sh`)
- **packages/** - Individual application configurations
