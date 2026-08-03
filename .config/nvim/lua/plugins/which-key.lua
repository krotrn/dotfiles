return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    spec = {
      { "<leader>b", group = "Buffer" },
      { "<leader>c", group = "Code" },
      { "<leader>f", group = "Find" },
      { "<leader>g", group = "Git" },
      { "<leader>gh", group = "Hunks" },
      { "<leader>h", group = "Hunk" },
      { "<leader>q", group = "Session" },
      { "<leader>r", group = "Refactor" },
      { "<leader>t", group = "Toggle" },
      { "<leader>x", group = "Diagnostics" },
    },
  },
}