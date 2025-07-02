return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.5",
  dependencies = {
    "nvim-lua/plenary.nvim"
  },
  keys = {
    { "<Leader>g", ":Telescope git_files<CR>", desc = "Git Files", silent = true },
    { "<Leader>h", ":Telescope oldfiles<CR>", desc = "Recent Files", silent = true },
    { "<Leader>r", ":Telescope live_grep<CR>", desc = "Live Grep", silent = true },
  },
  config = function()
    require("telescope").setup({
      defaults = {
        mappings = {
          i = {
            ["<C-u>"] = false,
            ["<C-d>"] = false,
          },
        },
      },
    })
  end,
}