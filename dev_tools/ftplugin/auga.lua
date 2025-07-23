local set = vim.opt_local
set.shiftwidth = 4
set.tabstop = 4
set.number = true
set.relativenumber = true
set.expandtab = true
set.commentstring = "// %s"
vim.api.nvim_create_autocmd("BufEnter", {
	buffer = 0,
	once = true,
	callback = function()
		vim.bo.syntax = "javascript"
	end,
})

vim.cmd("compiler odin")

set.syntax = "javascript"
