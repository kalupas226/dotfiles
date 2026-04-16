# Key Bindings Cheat Sheet

Quick reference for custom shortcuts configured in this dotfiles repo.

## macOS (Karabiner)

| Key | Action | Source |
|---|---|---|
| `Caps Lock` | Remapped to `Left Control` | `packages/karabiner/.config/karabiner/karabiner.json` |
| `Left Command` (tap alone) | Switch input to `Eisuu` | `packages/karabiner/.config/karabiner/karabiner.json` |
| `Right Command` (tap alone) | Switch input to `Kana` | `packages/karabiner/.config/karabiner/karabiner.json` |

## AeroSpace (Window Manager)

| Key | Action | Source |
|---|---|---|
| `Alt + h/j/k/l` | Focus left/down/up/right | `packages/aerospace/.config/aerospace/aerospace.toml` |
| `Alt + Shift + h/j/k/l` | Move window left/down/up/right | `packages/aerospace/.config/aerospace/aerospace.toml` |
| `Alt + 1-9` | Switch to workspace 1-9 | `packages/aerospace/.config/aerospace/aerospace.toml` |
| `Alt + Shift + 1-9` | Move window to workspace 1-9 | `packages/aerospace/.config/aerospace/aerospace.toml` |
| `Alt + m` | Toggle fullscreen | `packages/aerospace/.config/aerospace/aerospace.toml` |
| `Alt + Tab` | Switch to previous workspace | `packages/aerospace/.config/aerospace/aerospace.toml` |
| `Alt + /` | Toggle tiles horizontal/vertical | `packages/aerospace/.config/aerospace/aerospace.toml` |
| `Alt + ,` | Toggle accordion horizontal/vertical | `packages/aerospace/.config/aerospace/aerospace.toml` |
| `Alt + -/=` | Resize smart -50/+50 | `packages/aerospace/.config/aerospace/aerospace.toml` |
| `Alt + Shift + ;` | Enter service mode | `packages/aerospace/.config/aerospace/aerospace.toml` |

## Terminal (WezTerm / zsh / tmux)

### WezTerm

| Key | Action | Source |
|---|---|---|
| `Option + Left` | Sends `Esc+b` (back one word) | `packages/wezterm/.config/wezterm/keybinds.lua` |
| `Option + Right` | Sends `Esc+f` (forward one word) | `packages/wezterm/.config/wezterm/keybinds.lua` |
| `Ctrl + =` | Increase font size | `packages/wezterm/.config/wezterm/keybinds.lua` |
| `Ctrl + -` | Decrease font size | `packages/wezterm/.config/wezterm/keybinds.lua` |
| `Cmd + v` | Paste from clipboard | `packages/wezterm/.config/wezterm/keybinds.lua` |

### zsh

| Key | Action | Source |
|---|---|---|
| `Ctrl + r` | `fzf` fuzzy history search | `packages/zsh/.zshrc` (fzf integration) |
| `Ctrl + t` | `fzf` file finder (insert path) | `packages/zsh/.zshrc` (fzf integration) |
| `Alt + c` | `fzf` directory search + cd | `packages/zsh/.zshrc` (fzf integration) |
| `**<Tab>` | `fzf` completion trigger (e.g. `cd **<Tab>`) | `packages/zsh/.zshrc` (fzf integration) |
| `Ctrl + p` | Prefix history search (previous) | `packages/zsh/.zshrc` |
| `Ctrl + n` | Prefix history search (next) | `packages/zsh/.zshrc` |
| `Ctrl + z` | `zoxide` interactive directory jump | `packages/zsh/.zshrc` |
| `Ctrl + @` | `ghq` + `fzf` repo picker (`cdrepo`) | `packages/zsh/.zshrc` |

### tmux

`prefix` is the tmux default (`Ctrl + b`).

| Key | Action | Source |
|---|---|---|
| `prefix + \|` | Split pane vertically (keep cwd) | `packages/tmux/.tmux.conf` |
| `prefix + -` | Split pane horizontally (keep cwd) | `packages/tmux/.tmux.conf` |
| `prefix + H/J/K/L` | Resize pane | `packages/tmux/.tmux.conf` |
| `prefix + t` | New window (keep cwd) | `packages/tmux/.tmux.conf` |
| `prefix + n/p` | Next/previous window | `packages/tmux/.tmux.conf` |
| `prefix + s` | Open session chooser (`choose-tree`) | `packages/tmux/.tmux.conf` |
| `copy-mode` + `v` | Begin selection | `packages/tmux/.tmux.conf` |
| `copy-mode` + `y` | Copy selection to macOS clipboard | `packages/tmux/.tmux.conf` |

## Neovim

`<leader>` is currently default (`\`) because no custom mapleader is set.

| Key | Action | Source |
|---|---|---|
| Visual `>` / `<` | Indent and keep selection | `packages/nvim/.config/nvim/lua/config/base-keymaps.lua` |
| `[b` / `]b` | Previous/next buffer | `packages/nvim/.config/nvim/lua/config/base-keymaps.lua` |
| `<leader>bd` | Delete buffer | `packages/nvim/.config/nvim/lua/config/base-keymaps.lua` |
| `<leader>bw` | Wipeout buffer | `packages/nvim/.config/nvim/lua/config/base-keymaps.lua` |
| `<leader>bl` | List buffers | `packages/nvim/.config/nvim/lua/config/base-keymaps.lua` |
| `<leader>e` | Toggle Explorer | `packages/nvim/.config/nvim/lua/plugins/nvim-tree.lua` |
| `<leader>E` | Reveal current file in Explorer | `packages/nvim/.config/nvim/lua/plugins/nvim-tree.lua` |
| `<leader>g` | Telescope: git files | `packages/nvim/.config/nvim/lua/plugins/telescope.lua` |
| `<leader>h` | Telescope: recent files | `packages/nvim/.config/nvim/lua/plugins/telescope.lua` |
| `<leader>r` | Telescope: live grep | `packages/nvim/.config/nvim/lua/plugins/telescope.lua` |
| `[d` / `]d` | Previous/next diagnostic | `packages/nvim/.config/nvim/lua/config/diagnostics.lua` |
| `<leader>d` | Open diagnostic float | `packages/nvim/.config/nvim/lua/config/diagnostics.lua` |
| `<leader>q` | Open diagnostic location list | `packages/nvim/.config/nvim/lua/config/diagnostics.lua` |
| `gd` / `gD` / `gi` / `gr` / `gy` | LSP def/decl/impl/refs/type def | `packages/nvim/.config/nvim/lua/plugins/nvim-cmp.lua` |
| `K` / `<C-k>` | LSP hover / signature help | `packages/nvim/.config/nvim/lua/plugins/nvim-cmp.lua` |
| `<leader>rn` | LSP rename | `packages/nvim/.config/nvim/lua/plugins/nvim-cmp.lua` |
| `<leader>ca` | LSP code action | `packages/nvim/.config/nvim/lua/plugins/nvim-cmp.lua` |
| `<leader>f` | LSP format | `packages/nvim/.config/nvim/lua/plugins/nvim-cmp.lua` |
| Insert `<Tab>` / `<S-Tab>` | Next/previous completion item | `packages/nvim/.config/nvim/lua/plugins/nvim-cmp.lua` |
| Insert `<C-Space>` | Trigger completion | `packages/nvim/.config/nvim/lua/plugins/nvim-cmp.lua` |
