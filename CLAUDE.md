# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- **Install everything**: `./install.sh` or `mise run dotfiles:install`
- **Check for updates** (read-only): `mise run dotfiles:check-updates` or `./scripts/check-updates.sh`
- **Run a specific update check**: `./scripts/check-updates.sh brew|mise|npm|sheldon`

There is no automated test suite. Validate changes by running `./install.sh` or checking that symlinks under `$HOME` are correct after edits.

## Architecture

This repo uses a **package-based layout**: each directory under `packages/` mirrors the filesystem structure relative to `$HOME`. `install.sh` symlinks every dotfile (files/dirs starting with `.`) from each package into `$HOME`.

Example: `packages/zsh/.zshrc` → `~/.zshrc`; `packages/nvim/.config/nvim/init.lua` → `~/.config/nvim/init.lua`.

Key files:
- **`Brewfile`** — source of truth for all Homebrew formulae/casks
- **`packages/mise/.config/mise/config.toml`** — tool version pins (e.g., Node) and mise task definitions
- **`packages/npm/global-packages.txt`** — global npm CLIs installed by `install.sh`
- **`scripts/lib/ui.sh`** — shared shell UI helpers (`step`, `ok`, `warn`, `skip`, etc.) sourced by all scripts
- **`scripts/checks/`** — individual check scripts invoked by `check-updates.sh`

## Shell Script Conventions

- Scripts use `zsh` (`install.sh`) or `bash` (`scripts/`); always `set -e` / `set -euo pipefail`
- 4-space indentation; explicit conditionals
- Source `scripts/lib/ui.sh` for all user-facing output; never use raw `echo` for status messages
- Kebab-case filenames in `scripts/`; package folder names match the tool name in lowercase

## Commit Style

Short, imperative, capitalized: `Fix aliases`, `Update Brewfile`, `Add wezterm config`.
