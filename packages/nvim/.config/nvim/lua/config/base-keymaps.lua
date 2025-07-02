-- Key mappings
local map = vim.keymap.set

-- Insert mode mappings (bracket completion handled by nvim-autopairs)

-- Visual mode mappings
map("v", ">", ">gv")
map("v", "<", "<gv")

-- Normal mode mappings
map("n", "<C-h>", ":bprev<CR>", { silent = true })
map("n", "<C-l>", ":bnext<CR>", { silent = true })

-- Command mode mappings
map("c", "<C-p>", "<Up>")
map("c", "<C-n>", "<Down>")