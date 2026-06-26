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

Skip prompts before running official remote installer scripts:

```bash
./install.sh --skip-confirmation
```

### What gets installed

- **Homebrew** - Package manager for macOS
- **mise** - Development environment manager
- **CLI tools** - bat, eza, fzf, ripgrep, starship, neovim, etc.
- **GUI applications** - ChatGPT, CleanShot, Wezterm, VSCode, Raycast, etc.
- **Fonts** - Hack Nerd Font
- **Node.js** - Pinned via mise
- **Dotfiles** - Automatically symlinked to your home directory

Restart your terminal or run `exec zsh` to load the new configuration.

After that, use the `dotfiles` helper from `~/.local/bin` for routine maintenance:

```bash
dotfiles check
```

### Post-install manual steps

Some tools require a one-time manual step after `install.sh`:

- **tmux plugins (TPM)**: open tmux and run `prefix + I`
  - TPM plugins are not lockfile-pinned
  - Update intentionally with `prefix + U`
- **Neovim plugins (lazy.nvim)**: open Neovim and run `:Lazy sync`
  - Plugins are locked by `packages/nvim/.config/nvim/lazy-lock.json`
  - Check updates with `:Lazy check`
  - Update intentionally with targeted `:Lazy update <plugin>`
  - Review the lockfile diff before committing
- **Homebrew apps/tools**: some packages need first-run setup, permissions (e.g. macOS Security & Privacy), or in-app configuration—check each tool as needed
- **AeroSpace**:
  - Grant **Accessibility** permission in `System Settings → Privacy & Security → Accessibility`
  - Run `defaults write com.apple.spaces spans-displays -bool true && killall SystemUIServer` (required for multi-monitor support)
  - Reload config: `alt-shift-; → esc`
- **Claude Code plugins**: reinstall plugins from the marketplace (`/plugins` in Claude Code)
- **pfw (Point-Free Way CLI)**: follow the setup instructions at https://github.com/pointfreeco/pfw
- **Logi Tune**: install manually (not managed by Homebrew in this repo). Reference: https://www.logitech.com/assets/66219/5/brio-500.pdf
- **macOS settings**: set these in System Settings (paths can vary by macOS version)
  - Mission Control: `Desktop & Dock` → disable "Automatically rearrange Spaces based on most recent use"
  - Trackpad: `Trackpad` → enable "Tap to click"
  - Trackpad: `Accessibility` → `Pointer Control` → `Trackpad Options...` → enable dragging and choose "Three Finger Drag"

## Maintenance

- Node: pinned via mise in `packages/mise/.config/mise/config.toml`
- npm CLIs: prefer project-local `devDependencies`, `npm dlx`/`npx`, or Homebrew casks/formulae over global npm installs
- Git: default identity uses GitHub noreply; override per machine with `~/.gitconfig.local` if needed
- Updates check (one-shot, no writes): `dotfiles check`
  - Homebrew (`brew update --quiet` + `brew outdated`)
  - mise tools (`mise outdated`)
  - sheldon plugins (pinned `rev` vs latest tags)
- Agent skills: see `skills/README.md`
- Claude Code + tmux:
  - Claude Code statusline renders as two rows so long directory and branch names do not hide model/context/cost/elapsed details
  - row 1 shows directory, branch, dirty/ahead/behind, and (when present) the PR number colored by review state; row 2 shows model, the context gauge with token usage (`used/size`, falling back to a percentage), cost, and elapsed time
  - the statusline uses Nerd Font icons (folder/branch/model/clock/PR); these need the Hack Nerd Font (in `Brewfile`) and the `Hack Nerd Font Mono` fallback configured in `packages/wezterm/.config/wezterm/wezterm.lua` (git dirty/ahead/behind use plain `*`/`⇡`/`⇣` symbols)
  - Claude hooks record the latest session cwd under `$TMPDIR/claude-cwd-state`; tmux bindings use the latest matching Claude cwd for `claude agents` panes
  - interactive zsh auto-starts a `home` tmux session with a `main` window, except in Claude/Codex/VS Code terminals
  - tmux bindings for shell/lazygit popup and pane splits otherwise fall back to `pane_current_path`
  - `prefix + t` and `prefix + T` prompt for stable window/session names
  - `prefix + P` opens a `ghq` + `fzf` project picker that switches to an existing project session or creates one with a `main` window
  - `prefix + G` opens `lazygit` in a bottom pane from the Claude-aware cwd
- If `brew bundle` or `mise install` fails mid-run, fix the cause then rerun `dotfiles install`.

## Repository Structure

This repository uses a package-based organization, with shared agent skills at the repository root:

```
.
├── packages/
│   ├── aerospace/  # AeroSpace window manager configuration
│   ├── bin/        # User-facing CLI helpers installed into ~/.local/bin
│   ├── claude/     # Claude Code settings and configurations
│   ├── git/        # Git configuration
│   ├── karabiner/  # Karabiner-Elements configuration
│   ├── lazygit/    # Lazygit configuration
│   ├── mise/       # Development environment manager configuration
│   ├── npm/        # npm CLI defaults
│   ├── nvim/       # Neovim configuration
│   ├── sheldon/    # Shell plugin manager configuration
│   ├── starship/   # Starship prompt configuration
│   ├── tmux/       # Terminal multiplexer configuration
│   ├── wezterm/    # Terminal emulator configuration
│   └── zsh/        # Zsh shell configuration
└── skills/         # Shared Agent Skills; see skills/README.md
```

Each package contains dotfiles in their expected directory structure. The installation script automatically creates symlinks from package files to their target locations in your home directory.

## Configuration Files

- **packages/mise/.config/mise/config.toml** - mise tool pins
- **Brewfile** - Homebrew package definitions
- **install.sh** - Main installation script with custom symlinking logic
- **scripts/** - repository maintenance scripts (install/check/update helpers such as `check-updates.sh`, `lib/ui.sh`)
- **packages/bin/.local/bin/dotfiles** - small launcher for install/check/help commands
- **packages/bin/.local/bin/tmux-open** - tmux helper for opening popups, panes, and windows from a Claude-aware cwd
- **packages/bin/.local/bin/tmux-project** - tmux helper for opening project sessions from a `ghq` + `fzf` picker
- **packages/claude/.claude/statusline-command.sh** - Claude Code two-row statusline
- **packages/claude/.claude/hooks/record-cwd-state.sh** - Claude Code hook that records session cwd state for `tmux-open`
- **packages/bin/.local/bin/** - user-facing CLI helpers; prefer this location for agent/task utilities instead of `scripts/`
- **packages/** - Individual application configurations
- **KEYBINDINGS.md** - cheat sheet for custom macOS/terminal/Neovim keybindings
