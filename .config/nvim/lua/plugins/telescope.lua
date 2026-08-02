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