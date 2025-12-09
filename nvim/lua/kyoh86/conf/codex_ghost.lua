local ok, ghost = pcall(require, "kyoh86.poc.codex_ghost")
if not ok then
	return
end

ghost.setup({
	auto_trigger = false,
	debounce_ms = 200,
	context_before = 120,
	context_after = 60,
	disable_buftypes = { "help", "prompt", "quickfix", "terminal" },
})

vim.keymap.set("i", "<C-g>g", function()
	ghost.request()
end, { desc = "Codex ghost: request" })
vim.keymap.set("i", "<C-g>a", function()
	ghost.accept()
end, { desc = "Codex ghost: accept" })
vim.keymap.set("i", "<C-g>d", function()
	ghost.dismiss()
end, { desc = "Codex ghost: dismiss" })
vim.keymap.set("n", "<leader>tg", function()
	local enabled = ghost.toggle()
	vim.notify(string.format("Codex ghost %s", enabled and "enabled" or "disabled"))
end, { desc = "Codex ghost: toggle" })
