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
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
          },
        },
      })

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
      })

      vim.keymap.set("n", "gd", vim.lsp.buf.definition)
      vim.keymap.set("n", "gr", vim.lsp.buf.references)
      vim.keymap.set("n", "K", vim.lsp.buf.hover)
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action)
    end,
  },
}