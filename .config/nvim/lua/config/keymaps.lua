local map = vim.keymap.set

map("n", "]h", "<cmd>Gitsigns next_hunk<CR>")
map("n", "[h", "<cmd>Gitsigns prev_hunk<CR>")
map("n", "<leader>hp", "<cmd>Gitsigns preview_hunk<CR>")
map("n", "<leader>hs", "<cmd>Gitsigns stage_hunk<CR>")
map("n", "<leader>hr", "<cmd>Gitsigns reset_hunk<CR>")