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
			{ "<leader>bo", function() Snacks.bufdelete.other() end, desc = "Delete other buffers" },
			{ "<leader>.", function() Snacks.scratch() end, desc = "Scratch buffer" },
			{ "<leader>uz", function() Snacks.zen() end, desc = "Zen mode" },
		},
		init = function()
			-- <leader>u toggles; which-key shows each one's current state
			vim.api.nvim_create_autocmd("User", {
				pattern = "VeryLazy",
				callback = function()
					Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
					Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
					Snacks.toggle.option("relativenumber", { name = "Relative numbers" }):map("<leader>uL")
					Snacks.toggle.diagnostics():map("<leader>ud")
					Snacks.toggle.inlay_hints():map("<leader>uh")
					Snacks.toggle({
						name = "Diagnostic lines",
						get = function()
							return vim.diagnostic.config().virtual_lines ~= false
								and vim.diagnostic.config().virtual_lines ~= nil
						end,
						set = function(on)
							-- full multi-line messages under the code, instead of the one-line tail
							vim.diagnostic.config({ virtual_lines = on, virtual_text = not on and { prefix = "●", spacing = 4 } })
						end,
					}):map("<leader>ul")
					Snacks.toggle.option("conceallevel", { off = 0, on = 2, name = "Conceal" }):map("<leader>uc")
				end,
			})
		end,
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
