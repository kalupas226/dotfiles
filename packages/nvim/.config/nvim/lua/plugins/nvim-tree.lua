return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<C-e>", ":NvimTreeToggle<CR>", desc = "Toggle NvimTree", silent = true },
    { "<Leader>n", ":NvimTreeFindFile<CR>", desc = "Find in NvimTree", silent = true },
  },
  config = function()
    require("nvim-tree").setup({
      view = {
        width = 30,
      },
      renderer = {
        group_empty = true,
      },
      filters = {
        dotfiles = false,
      },
    })
  end,
}