vim.g.mapleader = " "
vim.keymap.set("n", "J", "10j")
vim.keymap.set("n", "K", "10k")
vim.keymap.set("n", "<leader>j", "J")
vim.keymap.set("v", "<leader>s", function()
	local target = vim.fn.input("Search for: ")
	if target == "" then
		return
	end
	local escaped_tag = vim.fn.escape(target, [[\/.*$^]])
	local replacement = vim.fn.input("Replace with: ")
	local escaped_rep = vim.fn.escape(replacement, [[\/]])
	local cmd = string.format(":s/\\%%V%s/%s/g", escaped_tag, escaped_rep)
	vim.api.nvim_feedkeys(cmd, "n", false)
end, { desc = "Substitute in selection" })
