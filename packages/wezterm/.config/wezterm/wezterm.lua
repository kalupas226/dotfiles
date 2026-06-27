local wezterm = require 'wezterm'
local keybinds = require('keybinds')

return {
  font = wezterm.font_with_fallback({
    'JetBrains Mono',
    'Hiragino Sans',
  }),
  font_size = 16.0,
  color_scheme = 'Catppuccin Mocha',
  disable_default_key_bindings = true,
  use_ime = true,
  window_background_opacity = 0.80,
  macos_window_background_blur = 20,
  window_decorations = "RESIZE",
  window_padding = {
    left = 20,
    right = 20,
    top = 16,
    bottom = 16,
  },
  enable_tab_bar = false,
  window_frame = {
    inactive_titlebar_bg = "none",
    active_titlebar_bg = "none",
  },
  window_background_gradient = {
    colors = {
      '#0b0f14',
      '#11111b',
      '#181825',
    },
  },
  keys = keybinds.keys,
}
