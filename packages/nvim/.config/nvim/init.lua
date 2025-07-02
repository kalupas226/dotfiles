-- Basic options
vim.opt.showcmd = true
vim.opt.number = true
vim.opt.title = true
vim.opt.smartindent = true
vim.opt.visualbell = true
vim.opt.showmatch = true
vim.opt.wildmode = "list:longest"
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.wrapscan = true
vim.opt.hlsearch = true
vim.opt.completeopt = {"menuone", "noinsert"}
vim.opt.history = 200
vim.opt.termguicolors = true

-- Encoding
vim.opt.encoding = "utf-8"
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.updatetime = 300
vim.opt.signcolumn = "yes"

-- Key mappings
local map = vim.keymap.set

-- Insert mode mappings
map("i", "{<CR>", "{}<Left><CR><Esc><S-o>")
map("i", "[<CR>", "[]<Left><CR><Esc><S-o>")
map("i", "(<CR>", "()<Left><CR><Esc><S-o>")

-- Visual mode mappings
map("v", ">", ">gv")
map("v", "<", "<gv")

-- Normal mode mappings
map("n", "<C-h>", ":bprev<CR>", { silent = true })
map("n", "<C-l>", ":bnext<CR>", { silent = true })

-- Command mode mappings
map("c", "<C-p>", "<Up>")
map("c", "<C-n>", "<Down>")

-- Setup lazy.nvim
require("config.lazy")
