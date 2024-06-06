vim.keymap.set("n", "<leader>tit", [[<cmd>Ripgrep -i to]] .. [[do<cr><cmd>lua require("kyoh86.conf.todo").resize_window_to_fit_content()<cr>]], { remap = false, desc = "To" .. "Doを検索する" })
vim.keymap.set("n", "<leader><leader>t", [[<cmd>lua require("kyoh86.conf.todo").resize_window_to_fit_content()<cr>]], { remap = false, desc = "作業メモを編集する" })
local filename = "~/.local/state/to" .. "do.md"
return {
  resize_window_to_fit_content = function()
    local winid = vim.fn.bufwinid(filename)
    if winid < 0 then
      vim.cmd([[topleft new ]] .. filename)
      winid = vim.fn.bufwinid(filename)
    else
      vim.api.nvim_set_current_win(winid)
    end
    local line_count = vim.api.nvim_buf_line_count(0)
    vim.api.nvim_win_set_height(winid, line_count + 1)
  end,
}
