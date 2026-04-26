return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local colors = require("catppuccin.palettes").get_palette("mocha")
    local theme = require("lualine.themes.catppuccin-nvim")

    local statusline_bg = colors.surface0
    for _, mode in ipairs({ "normal", "insert", "visual", "replace", "command", "terminal", "inactive" }) do
      theme[mode].c = theme[mode].c or {}
      theme[mode].c.bg = statusline_bg
    end

    require("lualine").setup({
      options = {
        theme = theme,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        disabled_filetypes = {
          statusline = {},
          winbar = {},
        },
        ignore_focus = {},
        always_divide_middle = true,
        globalstatus = false,
        refresh = {
          statusline = 1000,
          tabline = 1000,
          winbar = 1000,
        }
      },
      sections = {
        lualine_a = {},
        lualine_b = {"branch"},
        lualine_c = {"filename"},
        lualine_x = {"filetype"},
        lualine_y = {},
        lualine_z = {"location"}
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {"filename"},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {}
      },
      tabline = {
        lualine_a = {"buffers"},
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {"tabs"}
      },
      winbar = {},
      inactive_winbar = {},
      extensions = {}
    })
  end,
}
