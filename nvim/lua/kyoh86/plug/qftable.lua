---@type LazySpec
local spec = {
  "kyoh86/denops-qftable.vim",
  config = function()
    vim.keymap.set({ "ca" }, "qft", "QfTable")
    vim.keymap.set({ "ca" }, "qftable", "QfTable")
    vim.keymap.set({ "ca" }, "Qftable", "QfTable")
    vim.keymap.set({ "n", "v" }, "<leader>qt", "<cmd>QfTable<cr>", { remap = false, desc = "QuickfixのリストをMarkdownのテーブルとして入力する" })
  end,
}
return spec
