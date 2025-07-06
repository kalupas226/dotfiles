return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      flavour = "mocha",
      transparent_background = true,
      term_colors = false,
      background = {
        light = "latte",
        dark = "mocha",
      },
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        diffview = false,
        telescope = {
          enabled = true
        }
      },
      custom_highlights = function(colors)
        return {
          DiffAdd = { fg = colors.green },
          DiffDelete = { fg = colors.red },
          DiffText = { fg = colors.blue },
        }
      end,
    })
    vim.cmd.colorscheme "catppuccin"
  end,
}
