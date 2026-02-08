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

    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function(data)
        if data.file == "" then
          return
        end
        if vim.fn.isdirectory(data.file) == 1 then
          return
        end
        local filename = vim.fn.fnamemodify(data.file, ":t")
        if filename == "COMMIT_EDITMSG" or filename == "MERGE_MSG" or filename == "TAG_EDITMSG" or filename == "SQUASH_MSG" then
          return
        end
        vim.cmd("NvimTreeFindFile")
        vim.cmd("wincmd p")
      end,
    })
  end,
}
