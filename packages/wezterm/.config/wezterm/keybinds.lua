local wezterm = require 'wezterm'

local M = {}

local mykeys = {}

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

M.keys = mykeys

return M
