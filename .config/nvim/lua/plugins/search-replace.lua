-- Project-wide search & replace with a live preview (ripgrep under the hood).
-- Edit the "Replace" field, then <localleader>r to apply (g? lists keys).
return {
	{
		"MagicDuck/grug-far.nvim",
		cmd = "GrugFar",
		opts = { headerMaxWidth = 80 },
		keys = {
			{
				"<leader>sr",
				function()
					require("grug-far").open()
				end,
				desc = "Search & replace (project)",
			},
			{
				"<leader>sw",
				function()
					require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
				end,
				desc = "Search & replace word under cursor",
			},
			{
				"<leader>sr",
				function()
					require("grug-far").with_visual_selection()
				end,
				mode = "v",
				desc = "Search & replace selection",
			},
			{
				"<leader>sf",
				function()
					require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } })
				end,
				desc = "Search & replace (current file)",
			},
		},
	},
}
