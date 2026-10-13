return {
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		keys = {
			{ "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
			{ "<leader>gl", function() Snacks.lazygit.log_file() end, desc = "Lazygit: file history" },
			{ "<leader>go", function() Snacks.gitbrowse() end, desc = "Open on GitHub", mode = { "n", "v" } },
			{ "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete buffer (keep layout)" },
		},
		opts = {
			bigfile = { enabled = true },
			lazygit = { enabled = true },
			gitbrowse = { enabled = true },
			quickfile = { enabled = true },
			input = { enabled = true },
			terminal = {
				enabled = true,
			},
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
