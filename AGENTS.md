# AGENTS.md

This file provides guidance to AI coding agents working in this repository.

## Overview

This is a personal macOS dotfiles repo built around a package-based layout. Each directory under `packages/` mirrors a path under `$HOME`, and `install.sh` links those packages into place with GNU Stow.

Examples:
- `packages/zsh/.zshrc` -> `~/.zshrc`
- `packages/nvim/.config/nvim/init.lua` -> `~/.config/nvim/init.lua`
- `packages/bin/.local/bin/dotfiles` -> `~/.local/bin/dotfiles`
- `packages/bin/.local/bin/tmux-open` -> `~/.local/bin/tmux-open`
- `packages/claude/.claude/_settings-source/shared.json` -> `~/.claude/_settings-source/shared.json`

The repo contains both user configuration and maintenance tooling:
- `install.sh` installs and links everything
- `scripts/` contains maintenance and update-check scripts
- `packages/bin/.local/bin/` contains user-facing CLI helpers installed into `$HOME`
- `tests/` contains shell regression tests for helper scripts
- `skills/` contains shared Agent Skills

## Commands

- Install everything: `./install.sh`
- Install everything via installed helper: `dotfiles install`
- Check all updates via installed helper: `dotfiles check`
- Refresh update metadata before checking: `dotfiles check --refresh`
- Generate Claude Code user settings via installed helper: `dotfiles claude-settings`
- Check all updates directly: `./scripts/check-updates.sh`
- Run one update check: `dotfiles check brew`, `dotfiles check mise`, or `dotfiles check sheldon`
- List available update checks: `./scripts/check-updates.sh --list`

## Validation

There is no single unified automated test suite for the whole repo, but there are automated shell regression tests for focused helper scripts under `tests/`.

Use the narrowest validation that matches your change:
- `bash tests/claude-statusline.sh`
- `bash tests/claude-cwd-state-hook.sh`
- `bash tests/generate-claude-settings.sh`
- `bash tests/migrate-legacy-links-to-stow.sh`
- `bash tests/tmux-open.sh`
- `bash tests/tmux-run-in-pane.sh`
- `bash tests/tmux-project.sh`
- `./scripts/check-updates.sh --list` for CLI/script sanity
- `./scripts/migrate-legacy-links-to-stow.sh --dry-run` when changing Stow migration logic
- `./install.sh` when you change installation flow, symlinking behavior, package lists, or anything cross-cutting

For dotfile-only changes, also sanity-check the target symlink under `$HOME` after edits.

## Repository Structure

Top-level files:
- `Brewfile` - source of truth for Homebrew formulae/casks
- `install.sh` - main installer; links dotfiles with GNU Stow, installs TPM/Homebrew packages/mise tools/Claude Code
- `README.md` - human-facing setup and maintenance guide
- `KEYBINDINGS.md` - reference for configured shortcuts across macOS, AeroSpace, WezTerm, zsh, tmux, and Neovim

Packages:
- `packages/aerospace` - AeroSpace config
- `packages/bin` - installed helper CLIs such as `dotfiles`, `tmux-open`, and `tmux-project`
- `packages/claude` - Claude Code settings source, hooks, and statusline
- `packages/git` - `.gitconfig` and global ignore file
- `packages/karabiner` - Karabiner-Elements config
- `packages/lazygit` - Lazygit config
- `packages/mise` - mise tool pins
- `packages/npm` - npm safety defaults (`.npmrc`)
- `packages/nvim` - Neovim config
- `packages/sheldon` - shell plugin manager config
- `packages/starship` - prompt config
- `packages/tmux` - tmux config
- `packages/wezterm` - WezTerm config
- `packages/zsh` - zsh startup files, aliases, functions, completions

Maintenance code:
- `scripts/lib/ui.sh` - shared shell UI helpers (`step`, `note`, `ok`, `warn`, `skip`, `section_line`)
- `scripts/check-updates.sh` - dispatcher for update checks
- `scripts/checks/` - individual checks for brew/mise/sheldon
- `scripts/generate-claude-settings.sh` - manually merges Claude settings source JSON files from `~/.claude/_settings-source` into `~/.claude/settings.json`
- `scripts/migrate-legacy-links-to-stow.sh` - one-time helper for removing old repo-pointing symlinks before Stow takes over
- `tests/` - regression tests for helper scripts
- `skills/` - shared Agent Skills; see `skills/README.md`

## Important Behaviors

### install.sh

`install.sh` currently does more than symlink files. It:
- installs Homebrew if missing
- runs `brew bundle -v --file=Brewfile`
- links package dotfiles with `stow --no-folding`
- installs TPM if missing
- activates mise and runs `mise install`
- installs Claude Code if missing

When editing `install.sh`, preserve this ordering unless you have a concrete reason to change it. Homebrew packages run before Stow so `stow` is available for linking.

Claude Code user settings are generated explicitly, not from `install.sh`. After linking dotfiles and adding any machine-specific JSON files under `~/.claude/_settings-source/`, run `dotfiles claude-settings`.

If Stow conflicts with symlinks created by older versions of `install.sh`, use `./scripts/migrate-legacy-links-to-stow.sh --dry-run` and then `./scripts/migrate-legacy-links-to-stow.sh` explicitly. Do not hide that migration inside the normal installer.

### mise

`packages/mise/.config/mise/config.toml` currently defines:
- `node = "24.14.1"`

### dotfiles helper

`packages/bin/.local/bin/dotfiles` is the user-facing launcher for routine dotfiles maintenance.

Supported commands:
- `dotfiles install`
- `dotfiles check [--refresh] [brew|mise|sheldon...]`
- `dotfiles claude-settings`
- `dotfiles help`

### Claude Code and tmux

- Claude Code uses `packages/claude/.claude/statusline-command.sh` for the statusline
- `packages/claude/.claude/hooks/record-cwd-state.sh` records recent Claude working directories for `tmux-open`
- `packages/bin/.local/bin/tmux-open` opens panes, popups, and lazygit from a Claude-aware cwd when possible
- `packages/bin/.local/bin/tmux-run-in-pane` sends commands into an existing pane from a Claude-aware cwd
- `packages/bin/.local/bin/tmux-project` opens project sessions from a `ghq` + `fzf` picker

## Shell Conventions

- `install.sh` uses `zsh` with `set -e`
- files under `scripts/` use `bash` with `set -euo pipefail`
- use 4-space indentation in shell scripts
- prefer explicit conditionals and guard clauses
- source `scripts/lib/ui.sh` for user-facing script output instead of ad hoc status printing

Repository-specific placement rules:
- put user-facing or agent-facing CLIs in `packages/bin/.local/bin/`
- keep `scripts/` for repo maintenance/install/check logic
- keep package names lowercase and aligned to the tool/app name
- keep script filenames in kebab-case

## Editing Guidance

- Update `README.md` too if you change setup flow, package coverage, or documented workflows
- Update `KEYBINDINGS.md` when changing shortcuts in AeroSpace, Karabiner, tmux, WezTerm, zsh, or Neovim
- Update `Brewfile` and `packages/mise/.config/mise/config.toml` consistently when changing installed tooling
- Do not assume an empty repo-local `.gitignore` means generated paths are meant to be tracked; global ignore rules may be active via `core.excludesFile`
- Prefer minimal, targeted edits because many files are installed directly into `$HOME`

## Commit Style

Use short, imperative, capitalized commit messages, for example:
- `Fix aliases`
- `Update Brewfile`
- `Add wezterm config`
