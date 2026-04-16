return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<Leader>e", ":NvimTreeToggle<CR>", desc = "Toggle Explorer", silent = true },
    { "<Leader>E", ":NvimTreeFindFile<CR>", desc = "Reveal in Explorer", silent = true },
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
