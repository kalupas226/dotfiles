-- Key mappings
local map = vim.keymap.set

-- Visual mode mappings
map("v", ">", ">gv")
map("v", "<", "<gv")

-- Normal mode mappings
map("n", "<C-h>", ":bprev<CR>", { silent = true })
map("n", "<C-l>", ":bnext<CR>", { silent = true })
map("n", "<leader>bd", ":bdelete<CR>", { silent = true, desc = "Delete buffer" })
map("n", "<leader>bw", ":bwipeout<CR>", { silent = true, desc = "Wipeout buffer" })
map("n", "<leader>bl", ":buffers<CR>", { silent = true, desc = "List buffers" })

-- Command mode mappings
map("c", "<C-p>", "<Up>")
map("c", "<C-n>", "<Down>")
