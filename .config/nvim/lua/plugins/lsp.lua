return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    opts = {},
  },

  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = {
        "lua_ls",
        "clangd",
        "jdtls",
        "ts_ls",
        "pyright",
        "jsonls",
        "yamlls",
        "bashls",
        "dockerls",
        "rust_analyzer",
        "gopls",
        "html",
        "cssls",
        "tailwindcss",
        "emmet_ls",
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      -- Diagnostics configuration
      vim.diagnostic.config({
        virtual_text = {
          prefix = "●",
          spacing = 4,
        },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.INFO] = " ",
            [vim.diagnostic.severity.HINT] = " ",
          },
        },
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = true,
        },
      })

      -- LSP server configurations
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
          },
        },
      })

      -- Enable all LSP servers
      vim.lsp.enable({
        "lua_ls",
        "clangd",
        "jdtls",
        "ts_ls",
        "pyright",
        "jsonls",
        "yamlls",
        "bashls",
        "dockerls",
        "rust_analyzer",
        "gopls",
        "html",
        "cssls",
        "tailwindcss",
        "emmet_ls",
      })

      -- LSP keymaps (buffer-local on attach)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(args)
          local map = function(keys, func, desc, mode)
            mode = mode or "n"
            vim.keymap.set(mode, keys, func, { buffer = args.buf, desc = "LSP: " .. desc })
          end

          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("gi", vim.lsp.buf.implementation, "Go to implementation")
          map("gr", vim.lsp.buf.references, "References")
          map("K", vim.lsp.buf.hover, "Hover documentation")
          map("<leader>D", vim.lsp.buf.type_definition, "Type definition")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "v" })
          map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>cs", vim.lsp.buf.signature_help, "Signature help")

          -- Inlay hints toggle (Neovim 0.10+)
          if vim.lsp.inlay_hint then
            map("<leader>th", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf }))
            end, "Toggle inlay hints")
          end

          -- Document highlight on CursorHold
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.supports_method("textDocument/documentHighlight") then
            local highlight_group = vim.api.nvim_create_augroup("LspDocumentHighlight", { clear = false })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = args.buf,
              group = highlight_group,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = args.buf,
              group = highlight_group,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })
    end,
  },
}