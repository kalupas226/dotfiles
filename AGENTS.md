# Repository Guidelines

## Project Structure & Module Organization

- `packages/` holds application-specific dotfiles (e.g., `packages/zsh`, `packages/tmux`, `packages/nvim`). Files are stored in their target path shape and are symlinked into `$HOME` by `install.sh`.
- `scripts/` contains helper scripts and checks (e.g., `scripts/check-updates.sh`, `scripts/checks/*.sh`, `scripts/lib/ui.sh`).
- `Brewfile` defines Homebrew dependencies.
- `install.sh` is the main entrypoint for setup and linking.

## Build, Test, and Development Commands

- `./install.sh` — installs Homebrew packages, mise tools, global npm CLIs, and symlinks dotfiles.
- `mise run dotfiles:install` — runs the install workflow via mise.
- `mise run dotfiles:check-updates` — reports updates for brew/mise/npm/sheldon without writing changes.
- `./scripts/check-updates.sh` — direct update-check runner if you are not using mise.

## Coding Style & Naming Conventions

- Shell scripts use `zsh` and `set -e`; keep indentation at 4 spaces and prefer readable, explicit conditionals.
- Use kebab-case for script filenames in `scripts/` (e.g., `check-updates.sh`).
- Keep package folder names lowercase and match tool names (e.g., `packages/starship`, `packages/wezterm`).

## Testing Guidelines

- There is no automated test suite. Validate changes by running:
  - `./install.sh` in a safe environment, or
  - `mise run dotfiles:check-updates` for non-invasive checks.
- For package edits, verify the symlinked paths under `$HOME` and ensure tools load cleanly.

## Commit & Pull Request Guidelines

- Commit messages are short, imperative, and capitalized (e.g., `Fix aliases`, `Update Brewfile`).
- PRs should include a concise summary, any manual steps required after install, and the commands used to verify changes.

## Security & Configuration Tips

- Treat `Brewfile` and `packages/mise/.config/mise/config.toml` as the source of truth for installs and tool pins.
- Prefer project-local npm tools; only add truly global CLIs to `packages/npm/global-packages.txt`.
