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
        desc = "Open Yazi",
      },
    },
    opts = {},
  },
}