return {
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },

    cmd = "Telescope",

    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help" },
      { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent Files" },
      { "<leader>fs", "<cmd>Telescope grep_string<CR>", desc = "Grep Word Under Cursor" },
      { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },
      { "<leader>fk", "<cmd>Telescope keymaps<CR>", desc = "Keymaps" },
      { "<leader>fc", "<cmd>Telescope commands<CR>", desc = "Commands" },
      { "<leader>ft", "<cmd>TodoTelescope<CR>", desc = "Todo Comments" },
    },

    opts = {
      defaults = {
        layout_strategy = "horizontal",
        sorting_strategy = "ascending",
        prompt_prefix = "   ",
        selection_caret = " ",
        path_display = { "smart" },

        vimgrep_arguments = {
          "rg",
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
        },
      },

      pickers = {
        find_files = {
          find_command = {
            "fd",
            "--type",
            "f",
            "--hidden",
            "--exclude",
            ".git",
          },
        },
      },
    },
  },
}