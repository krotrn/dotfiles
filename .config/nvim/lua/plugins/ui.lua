return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },

    opts = {
      formatters_by_ft = {
        lua = { "stylua" },

        javascript = { "prettier" },
        javascriptreact = { "prettier" },

        typescript = { "prettier" },
        typescriptreact = { "prettier" },

        json = { "prettier" },
        yaml = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        markdown = { "prettier" },

        cpp = { "clang_format" },
        c = { "clang_format" },

        java = { "google_java_format" },

        python = { "ruff_format" },

        sh = { "shfmt" },
      },

      format_on_save = {
        timeout_ms = 1000,
        lsp_format = "fallback",
      },
    },
  },
}