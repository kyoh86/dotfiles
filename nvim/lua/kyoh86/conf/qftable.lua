vim.api.nvim_create_user_command("QfTable", function(command)
  require("kyoh86.lib.qftable").command(command)
end, { nargs = "*", desc = "Show Quickfix as a Markdown table" })
for _, alias in ipairs({ "qft", "qftable", "Qftable" }) do
  vim.cmd(("cnoreabbrev <expr> %s getcmdtype() ==# ':' && getcmdline() ==# '%s' ? 'QfTable' : '%s'"):format(alias, alias, alias))
end
vim.keymap.set({ "n", "v" }, "<leader>qt", "<cmd>QfTable<cr>", { desc = "QuickfixのリストをMarkdownのテーブルとして入力する" })
