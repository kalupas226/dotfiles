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
- Prints manual setup reminders

After the first install, use the helper in `~/.local/bin` for routine maintenance:

```bash
dotfiles outdated
```

## Post-Install Steps

Some tools need one-time manual setup after `install.sh`.

The current checklist is printed by `install.sh` at the end of the install so the manual steps have one source of truth.

## Maintenance

- Check managed updates: `dotfiles outdated`
- Refresh update metadata before checking: `dotfiles outdated --refresh`
- Check a single source: `dotfiles outdated brew`, `dotfiles outdated mise`, or `dotfiles outdated sheldon`
- Diagnose local symlink health: `dotfiles doctor`
- Install or relink everything: `dotfiles install`
- Generate Claude Code settings: `dotfiles claude-settings`
- Node.js is pinned in `packages/mise/.config/mise/config.toml`
- Homebrew packages are defined in `Brewfile`
- Manual setup reminders are maintained in `install.sh`
- Neovim plugins are locked in `packages/nvim/.config/nvim/lazy-lock.json`
- Git identity defaults to GitHub noreply; override per machine with `~/.gitconfig.local`
- Prefer project-local `devDependencies`, `npm dlx`/`npx`, or Homebrew over global npm installs

If `brew bundle` or `mise install` fails mid-run, fix the cause and rerun `dotfiles install`.

If Stow reports conflicts from legacy symlinks created by older versions of `install.sh`, run:

```bash
scripts/migrate-legacy-links-to-stow.sh --dry-run
scripts/migrate-legacy-links-to-stow.sh
./install.sh
```

## Claude Code and tmux

- `~/.claude/settings.json` is generated manually with `dotfiles claude-settings`
- `packages/claude/.claude/_settings-source/shared.json` is repo-managed
- Add machine-specific Claude settings as any other `*.json` file in `~/.claude/_settings-source/`
- Claude Code uses `packages/claude/.claude/statusline-command.sh` for a compact two-row statusline
- `packages/claude/.claude/hooks/record-cwd-state.sh` records recent Claude working directories under `$TMPDIR/claude-cwd-state`
- tmux libexec helpers use that state to open shells, panes, and lazygit from the relevant Claude-aware directory
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
│   ├── tmux/       # tmux configuration and tmux-only libexec helpers
│   ├── wezterm/    # WezTerm configuration
│   └── zsh/        # zsh startup files and helpers
├── scripts/        # Maintenance, diagnostics, and update-check scripts
├── skills/         # Shared Agent Skills
└── tests/          # Shell regression tests
```

Useful references:

- `KEYBINDINGS.md` - custom macOS, terminal, tmux, zsh, and Neovim shortcuts
- `skills/README.md` - shared Agent Skills in this repo
- `AGENTS.md` - guidance for AI coding agents working in this repository
