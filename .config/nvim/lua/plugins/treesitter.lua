return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",

  config = function()
    local ts = require("nvim-treesitter")

    ts.setup({})

    ts.install({
      "bash",
      "c",
      "cpp",
      "css",
      "dockerfile",
      "html",
      "java",
      "javascript",
      "json",
      "lua",
      "markdown",
      "markdown_inline",
      "python",
      "sql",
      "tsx",
      "typescript",
      "vim",
      "vimdoc",
      "yaml",
    })
  end,
}