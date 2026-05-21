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
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")
        api.config.mappings.default_on_attach(bufnr)

        local opts = { buffer = bufnr, silent = true, nowait = true }
        vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<CR>", opts)
      end,
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
