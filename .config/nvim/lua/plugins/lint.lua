return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        javascript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescript = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        python = { "ruff" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        markdown = { "markdownlint" },
        dockerfile = { "hadolint" },
      }

      -- Auto-lint on save and insert leave
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("UserLintConfig", { clear = true }),
        callback = function()
          -- Only lint if the linter is available
          lint.try_lint()
        end,
      })

      vim.keymap.set("n", "<leader>cl", function()
        lint.try_lint()
      end, { desc = "Trigger linting" })
    end,
  },
}
