-- Diagnostic configuration
vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
    focusable = false,
    style = "minimal",
    max_width = 80,
    max_height = 20,
  },
})

-- Auto show diagnostics in floating window on cursor hold
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.diagnostic.open_float(nil, {
      focusable = false,
      close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
      border = "rounded",
      source = "always",
      prefix = " ",
      scope = "cursor",
    })
  end
})

-- Diagnostic signs with more visible icons
local signs = { 
  Error = "✘ ", 
  Warn = "▲ ", 
  Hint = "⚑ ", 
  Info = "● " 
}
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Open diagnostic float" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic quickfix" })

-- Custom diagnostic highlight colors (Catppuccin)
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(0, "DiagnosticFloatingError", { bg = "#313244", fg = "#f38ba8" })
    vim.api.nvim_set_hl(0, "DiagnosticFloatingWarn", { bg = "#313244", fg = "#fab387" })
    vim.api.nvim_set_hl(0, "DiagnosticFloatingInfo", { bg = "#313244", fg = "#89b4fa" })
    vim.api.nvim_set_hl(0, "DiagnosticFloatingHint", { bg = "#313244", fg = "#a6e3a1" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#313244" })
    vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#6c7086", bg = "#313244" })
  end,
})