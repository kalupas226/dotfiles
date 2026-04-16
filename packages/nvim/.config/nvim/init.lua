vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load configurations
require("config.base-options")
require("config.base-keymaps")
require("config.diagnostics")
require("config.lazy")
