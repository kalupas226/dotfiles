local wezterm = require 'wezterm'

local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local background = "#5c6d74"
  local foreground = "#FFFFFF"
  local edge_background = "none"

  if tab.is_active then
    background = "#ae8b2d"
    foreground = "#FFFFFF"
  end

  local edge_foreground = background

  local title = "   " .. wezterm.truncate_right(tab.active_pane.title, max_width - 1) .. "   "

  return {
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_LEFT_ARROW },
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = title },
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_RIGHT_ARROW },
  }
end)

return {
  keys = require('keybinds').keys,
  font = wezterm.font('JetBrains Mono'),
  font_size = 15.0,
  color_scheme = 'Solarized Dark Higher Contrast',
  window_close_confirmation = 'NeverPrompt',
  disable_default_key_bindings = true,
  leader = { 
    key = 'b',
    mods = 'CTRL',
    timeout_milliseconds = 1000 
  },
  use_ime = true,
  window_background_opacity = 0.85,
  macos_window_background_blur = 20,
  window_decorations = "RESIZE",
  hide_tab_bar_if_only_one_tab = true,
  window_frame = {
    inactive_titlebar_bg = "none",
    active_titlebar_bg = "none",
  },
  window_background_gradient = {
    colors = { "#000000" },
  },
  show_new_tab_button_in_tab_bar = false,
  colors = {
    tab_bar = {
      inactive_tab_edge = "none",
    },
  }
}
