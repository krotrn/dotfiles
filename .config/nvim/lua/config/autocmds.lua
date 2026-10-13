local group = vim.api.nvim_create_augroup("UserAutocmds", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

-- Briefly highlight yanked text
autocmd("TextYankPost", {
	group = group,
	callback = function()
		vim.hl.on_yank({ timeout = 150 })
	end,
})

-- Reopen files at the last cursor position
autocmd("BufReadPost", {
	group = group,
	callback = function(args)
		local ft = vim.bo[args.buf].filetype
		if ft == "gitcommit" or ft == "gitrebase" then
			return
		end
		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Keep splits equal when the terminal (or Hyprland window) is resized
autocmd("VimResized", {
	group = group,
	command = "tabdo wincmd =",
})

-- Close throwaway windows with q
autocmd("FileType", {
	group = group,
	pattern = { "help", "qf", "man", "checkhealth", "lspinfo", "notify" },
	callback = function(args)
		vim.bo[args.buf].buflisted = false
		vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = args.buf, silent = true, desc = "Close window" })
	end,
})
