return {
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    dependencies = {
      "folke/snacks.nvim",
    },
    keys = {
      {
        "<leader>e",
        "<cmd>Yazi<CR>",
        desc = "Open Yazi (Current File)",
      },
      {
        "<leader>cw",
        "<cmd>Yazi cwd<CR>",
        desc = "Open Yazi (Working Directory)",
      },
    },
    opts = {},
  },
}