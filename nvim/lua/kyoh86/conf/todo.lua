vim.keymap.set("n", "<leader>tit",
  [[<cmd>Ripgrep -i to]] .. [[do<cr><cmd>lua require("kyoh86.conf.todo").resize_window_to_fit_content()<cr>]],
  { remap = false, desc = "To" .. "Doを検索する" })
vim.keymap.set("n", "<leader><leader>t",
  [[<cmd>new ~/.local/state/to]] .. [[do.md<cr><cmd>lua require("kyoh86.conf.todo").resize_window_to_fit_content()<cr>]],
  { remap = false, desc = "作業メモを編集する" })
return {
  resize_window_to_fit_content = function()
    local line_count = vim.api.nvim_buf_line_count(0)
    vim.api.nvim_win_set_height(0, line_count + 1)
  end,
}
