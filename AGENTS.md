# AGENTS.md

This file provides guidance to AI coding agents working in this repository.

## Overview

This is a personal macOS dotfiles repo built around a package-based layout. Each directory under `packages/` mirrors a path under `$HOME`, and `install.sh` symlinks every dotfile from those packages into place.

Examples:
- `packages/zsh/.zshrc` -> `~/.zshrc`
- `packages/nvim/.config/nvim/init.lua` -> `~/.config/nvim/init.lua`
- `packages/bin/.local/bin/dotfiles` -> `~/.local/bin/dotfiles`
- `packages/bin/.local/bin/tmux-open` -> `~/.local/bin/tmux-open`

The repo contains both user configuration and maintenance tooling:
- `install.sh` installs/link everything
- `scripts/` contains maintenance and update-check scripts
- `packages/bin/.local/bin/` contains user-facing CLI helpers that are installed into `$HOME`
- `tests/` contains shell regression tests for helper scripts

## Commands

- Install everything: `./install.sh`
- Install everything via installed helper: `dotfiles install`
- Check all updates via installed helper: `dotfiles check`
- Check all updates directly: `./scripts/check-updates.sh`
- Run one update check: `dotfiles check brew`, `dotfiles check mise`, or `dotfiles check sheldon`
- List available update checks: `./scripts/check-updates.sh --list`

## Validation

There is no single unified automated test suite for the whole repo, but there are automated shell regression tests for focused helper scripts under `tests/`.

Use the narrowest validation that matches your change:
- `bash tests/claude-statusline.sh`
- `bash tests/claude-cwd-state-hook.sh`
- `bash tests/tmux-open.sh`
- `bash tests/tmux-project.sh`
- `./scripts/check-updates.sh --list` for CLI/script sanity
- `./install.sh` when you change installation flow, symlinking behavior, package lists, or anything cross-cutting

For dotfile-only changes, also sanity-check the target symlink under `$HOME` after edits.

## Repository Structure

Top-level files:
- `Brewfile` - source of truth for Homebrew formulae/casks
- `install.sh` - main installer; links dotfiles, installs TPM/Homebrew packages/mise tools/Claude Code
- `README.md` - most complete human-facing setup and maintenance guide
- `KEYBINDINGS.md` - reference for configured shortcuts across macOS, AeroSpace, WezTerm, zsh, tmux, and Neovim
- `CLAUDE.md` - currently mirrors agent guidance; check whether changes should stay aligned with `AGENTS.md`

Packages:
- `packages/aerospace` - AeroSpace config
- `packages/bin` - installed helper CLIs such as `dotfiles` and `tmux-open`
- `packages/claude` - Claude Code settings
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
- `tests/` - regression tests for helper scripts

## Important Behaviors

### install.sh

`install.sh` currently does more than symlink files. It:
- links all dotfiles found under `packages/*`
- installs TPM if missing
- installs Homebrew if missing
- runs `brew bundle -v --file=Brewfile`
- activates mise and runs `mise install`
- installs Claude Code if missing

When editing `install.sh`, preserve the current ordering unless you have a concrete reason to change it.

### mise

`packages/mise/.config/mise/config.toml` currently defines:
- `node = "24.14.1"`

### dotfiles helper

`packages/bin/.local/bin/dotfiles` is the user-facing launcher for routine dotfiles maintenance.

Supported commands:
- `dotfiles install`
- `dotfiles check [brew|mise|sheldon...]`
- `dotfiles help`

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
