# dotfiles

Personal macOS dotfiles organized as installable packages. Each directory under `packages/` mirrors the path it should occupy under `$HOME`, and `install.sh` links those packages with GNU Stow.

## Installation

### Prerequisites

```bash
sudo softwareupdate -i -a
xcode-select --install
```

### Quick install

The default checkout location is `~/.dotfiles`:

```bash
git clone https://github.com/kalupas226/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

`install.sh` prompts before running official remote installer scripts. To skip those prompts:

```bash
./install.sh --skip-confirmation
```

Restart your terminal, or run `exec zsh`, after installation.

## What `install.sh` Does

- Installs Homebrew if missing
- Runs `brew bundle -v --file=Brewfile`
- Links package dotfiles into `$HOME` with `stow --no-folding`
- Installs TPM if missing
- Activates mise and runs `mise install`
- Installs Claude Code if missing

After the first install, use the helper in `~/.local/bin` for routine maintenance:

```bash
dotfiles check
```

## Post-Install Steps

Some tools need one-time setup after `install.sh`:

- **tmux plugins (TPM)**: open tmux and run `prefix + I`
  - TPM plugins are not lockfile-pinned
  - Update intentionally with `prefix + U`
- **Neovim plugins (lazy.nvim)**: open Neovim and run `:Lazy sync`
  - Plugins are locked by `packages/nvim/.config/nvim/lazy-lock.json`
  - Check updates with `:Lazy check`
  - Update intentionally with targeted `:Lazy update <plugin>`
  - Review the lockfile diff before committing
- **Homebrew apps/tools**: complete any first-run permissions or in-app setup
- **AeroSpace**:
  - Grant Accessibility permission in `System Settings` -> `Privacy & Security` -> `Accessibility`
  - Run `defaults write com.apple.spaces spans-displays -bool true && killall SystemUIServer` for multi-monitor support
  - Reload config with `alt-shift-;` then `esc`
- **Claude Code plugins**: reinstall plugins from the marketplace with `/plugins`
- **Claude Code settings**:
  - Add any machine-specific source files to `~/.claude/_settings-source/*.json`
  - Generate the user settings with `dotfiles claude-settings`
- **pfw (Point-Free Way CLI)**: follow https://github.com/pointfreeco/pfw
- **Logi Tune**: install manually; it is not managed by Homebrew here
- **macOS settings**:
  - Mission Control: `Desktop & Dock` -> disable "Automatically rearrange Spaces based on most recent use"
  - Trackpad: `Trackpad` -> enable "Tap to click"
  - Trackpad: `Accessibility` -> `Pointer Control` -> `Trackpad Options...` -> enable dragging and choose "Three Finger Drag"

## Maintenance

- Check managed updates: `dotfiles check`
- Refresh update metadata before checking: `dotfiles check --refresh`
- Check a single source: `dotfiles check brew`, `dotfiles check mise`, or `dotfiles check sheldon`
- Install or relink everything: `dotfiles install`
- Generate Claude Code settings: `dotfiles claude-settings`
- Node.js is pinned in `packages/mise/.config/mise/config.toml`
- Homebrew packages are defined in `Brewfile`
- Neovim plugins are locked in `packages/nvim/.config/nvim/lazy-lock.json`
- Git identity defaults to GitHub noreply; override per machine with `~/.gitconfig.local`
- Prefer project-local `devDependencies`, `npm dlx`/`npx`, or Homebrew over global npm installs

If `brew bundle` or `mise install` fails mid-run, fix the cause and rerun `dotfiles install`.

If Stow reports conflicts from legacy symlinks created by older versions of `install.sh`, run:

```bash
scripts/migrate-legacy-links-to-stow.sh --dry-run
scripts/migrate-legacy-links-to-stow.sh
dotfiles install
```

## Claude Code and tmux

- `~/.claude/settings.json` is generated manually with `dotfiles claude-settings`
- `packages/claude/.claude/_settings-source/shared.json` is repo-managed
- Add machine-specific Claude settings as any other `*.json` file in `~/.claude/_settings-source/`
- Claude Code uses `packages/claude/.claude/statusline-command.sh` for a compact two-row statusline
- `packages/claude/.claude/hooks/record-cwd-state.sh` records recent Claude working directories under `$TMPDIR/claude-cwd-state`
- tmux helpers use that state to open shells, panes, and lazygit from the relevant Claude-aware directory
- Interactive zsh auto-starts a `home` tmux session with a `main` window, except in Claude, Codex, and VS Code terminals

## Repository Structure

```text
.
├── Brewfile
├── install.sh
├── packages/
│   ├── aerospace/  # AeroSpace configuration
│   ├── bin/        # User-facing helpers installed into ~/.local/bin
│   ├── claude/     # Claude Code settings source, hooks, and statusline
│   ├── git/        # Git configuration
│   ├── karabiner/  # Karabiner-Elements configuration
│   ├── lazygit/    # Lazygit configuration
│   ├── mise/       # mise tool pins
│   ├── npm/        # npm defaults
│   ├── nvim/       # Neovim configuration
│   ├── sheldon/    # zsh plugin pins
│   ├── starship/   # Starship prompt
│   ├── tmux/       # tmux configuration
│   ├── wezterm/    # WezTerm configuration
│   └── zsh/        # zsh startup files and helpers
├── scripts/        # Maintenance and update-check scripts
├── skills/         # Shared Agent Skills
└── tests/          # Shell regression tests
```

Useful references:

- `KEYBINDINGS.md` - custom macOS, terminal, tmux, zsh, and Neovim shortcuts
- `skills/README.md` - shared Agent Skills in this repo
- `AGENTS.md` - guidance for AI coding agents working in this repository
