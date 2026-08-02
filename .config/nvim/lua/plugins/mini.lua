return {
  {
    "echasnovski/mini.nvim",
    version = false,

    config = function()
      require("mini.surround").setup()
      require("mini.ai").setup()
      require("mini.indentscope").setup()
    end,
  },
}