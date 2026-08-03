return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      dashboard = {
        enabled = true,
        preset = {
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":Telescope find_files" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":Telescope live_grep" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":Telescope oldfiles" },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = " ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
          header = table.concat({
            "                                                                   ",
            "      ████ ██████           █████      ██                    ",
            "     ███████████             █████                            ",
            "     █████████ ███████████████████ ███   ███████████  ",
            "    █████████  ███    █████████████ █████ ██████████████  ",
            "   █████████ ██████████ █████████ █████ █████ ████ █████  ",
            " ███████████ ███    ███ █████████ █████ █████ ████ █████ ",
            "██████  █████████████████████ ████ █████ █████ ████ ██████",
          }, "\n"),
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { section = "recent_files", title = "Recent Files", limit = 5, padding = 1 },
          { section = "startup" },
        },
      },
      indent = {
        enabled = true,
        animate = {
          enabled = true,
        },
      },
      notifier = {
        enabled = true,
        timeout = 3000,
        style = "compact",
      },
      scope = {
        enabled = true,
      },
      statuscolumn = {
        enabled = true,
      },
      words = {
        enabled = true,
      },
    },
  },
}
