return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    local cmp = require("cmp")
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    -- Setup LSP capabilities
    local defaultCapabilities = cmp_nvim_lsp.default_capabilities()

    -- bash-language-server
    vim.lsp.config.bashls = {
      cmd = { "bash-language-server", "start" },
      capabilities = defaultCapabilities,
      settings = {
        bashIde = {
          globPattern = "**/*@(.sh|.inc|.bash|.command)",
          shellcheckPath = "shellcheck",
        },
      },
    }

    -- Swift (sourcekit-lsp)
    local swift_capabilities = vim.deepcopy(defaultCapabilities)
    swift_capabilities.workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      }
    }

    vim.lsp.config.sourcekit = {
      cmd = { "xcrun", "sourcekit-lsp" },
      capabilities = swift_capabilities,
    }

    -- JSON Language Server
    vim.lsp.config.jsonls = {
      capabilities = defaultCapabilities,
    }

    -- JavaScript/TypeScript Language Server
    vim.lsp.config.ts_ls = {
      capabilities = defaultCapabilities,
    }

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

    -- Global setup for LSP completion
    cmp.setup({
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "buffer" },
        { name = "path" },
      }),
      mapping = cmp.mapping.preset.insert({
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          else
            fallback()
          end
        end, { "i", "s" }),
      }),
      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },
    })
    
    -- Enhanced setup for gitcommit filetype (all buffers for committia.vim diff buffers)
    cmp.setup.filetype("gitcommit", {
      sources = cmp.config.sources({
        { 
          name = "buffer",
          option = {
            get_bufnrs = function()
              return vim.api.nvim_list_bufs() -- Get completion from all buffers including diff buffers
            end,
            keyword_length = 2,
          }
        },
        { name = "path" },
      })
    })
  end,
}