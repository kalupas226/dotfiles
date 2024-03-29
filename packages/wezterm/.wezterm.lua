local wezterm = require 'wezterm'

local mykeys = {
  -- KeyAssignment for pane
  {
    key = '|',
    mods = 'LEADER',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = '-',
    mods = 'LEADER',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'h',
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  {
    key = 'j',
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection 'Down',
  },
  {
    key = 'k',
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection 'Up',
  },
  {
    key = 'l',
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection 'Right',
  },
  {
    key = 'x',
    mods = 'LEADER',
    action = wezterm.action.CloseCurrentPane { 
      confirm = true 
    },
  },
  {
    key = 'H',
    mods = 'LEADER',
    action = wezterm.action.AdjustPaneSize {
      'Left', 
      3,
    },
  },
  {
    key = 'L',
    mods = 'LEADER',
    action = wezterm.action.AdjustPaneSize {
      'Right',
      3,
    },
  },
  {
    key = '[',
    mods = 'LEADER',
    action = wezterm.action.ActivateCopyMode,
  },
}

-- KeyAssignment for tab
table.insert(mykeys, {
    key = 't',
    mods = 'LEADER',
    action = wezterm.action.SpawnTab 'CurrentPaneDomain',
})
for i = 1, 8 do
  table.insert(mykeys, {
    key = tostring(i),
    mods = 'LEADER',
    action = wezterm.action.ActivateTab(i - 1),
  })
end

-- Enable key bindings like emacs (\x1b is escape character)
table.insert(mykeys, {
  key = 'LeftArrow',
  mods = 'OPT',
  action = wezterm.action.SendString '\x1bb',
})
table.insert(mykeys, {
  key = 'RightArrow',
  mods = 'OPT',
  action = wezterm.action.SendString '\x1bf',
})

-- Enable increase, decrease font size
table.insert(mykeys, {
  key = '=',
  mods = 'CTRL',
  action = wezterm.action.IncreaseFontSize,
})
table.insert(mykeys, {
  key = '-',
  mods = 'CTRL',
  action = wezterm.action.DecreaseFontSize,
})

-- Enable CMD+v paste
table.insert(mykeys, {
  key = 'v',
  mods = 'SUPER',
  action = wezterm.action.PasteFrom 'Clipboard',
})

return {
  font_size = 14.0,
  color_scheme = 'Solarized Dark Higher Contrast',
  window_close_confirmation = 'NeverPrompt',
  disable_default_key_bindings = true,
  leader = { 
    key = 'b',
    mods = 'CTRL',
    timeout_milliseconds = 1000 
  },
  keys = mykeys,
}
