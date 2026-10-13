return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")

      -- JS/TS linting comes from the eslint LSP (lsp.lua), which uses each
      -- project's own eslint version and config.
      lint.linters_by_ft = {
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
          -- Only run linters that are installed, so a missing hadolint or
          -- markdownlint doesn't error on every save
          local names = vim.tbl_filter(function(name)
            local linter = lint.linters[name]
            local cmd = type(linter) == "table" and linter.cmd
            if type(cmd) == "function" then cmd = cmd() end
            return type(cmd) == "string" and vim.fn.executable(cmd) == 1
          end, lint.linters_by_ft[vim.bo.filetype] or {})
          if #names > 0 then lint.try_lint(names) end
        end,
      })

      vim.keymap.set("n", "<leader>cl", function()
        lint.try_lint()
      end, { desc = "Trigger linting" })
    end,
  },
}
