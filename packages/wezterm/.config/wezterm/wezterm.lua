local wezterm = require 'wezterm'
local keybinds = require('keybinds')

return {
  font = wezterm.font('JetBrains Mono'),
  font_size = 16.0,
  color_scheme = 'Solarized Dark Higher Contrast',
  disable_default_key_bindings = true,
  use_ime = true,
  window_background_opacity = 0.80,
  macos_window_background_blur = 20,
  window_decorations = "RESIZE",
  enable_tab_bar = false,
  window_frame = {
    inactive_titlebar_bg = "none",
    active_titlebar_bg = "none",
  },
  window_background_gradient = {
    colors = { "#000000" },
  },
  keys = keybinds.keys,
}
