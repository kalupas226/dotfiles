return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    local lspconfig = require("lspconfig")
    local defaultCapabilities = require("cmp_nvim_lsp").default_capabilities()

    -- bash-language-server
    lspconfig.bashls.setup({
      cmd = { "bash-language-server", "start" },
      capabilities = defaultCapabilities,
      settings = {
        bashIde = {
          globPattern = "**/*@(.sh|.inc|.bash|.command)",
          shellcheckPath = "shellcheck",
        },
      },
    })

    -- Swift (sourcekit-lsp)
    local swift_capabilities = defaultCapabilities 
    swift_capabilities.workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      }
    }
    
    lspconfig.sourcekit.setup({
      cmd = { "xcrun", "sourcekit-lsp" },
      capabilities = swift_capabilities,
    })

    -- LSP keymaps
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        local opts = { buffer = ev.buf }
        
        -- Navigation
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)
        
        -- Documentation
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
        
        -- Code actions
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "<leader>f", function()
          vim.lsp.buf.format { async = true }
        end, opts)
        
      end,
    })

  end,
}
