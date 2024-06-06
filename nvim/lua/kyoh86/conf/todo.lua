vim.keymap.set("n", "<leader>tit", [[<cmd>Ripgrep -i to]] .. [[do<cr>]], { remap = false, desc = "To" .. "Doを検索する" })
vim.keymap.set("n", "<leader><leader>t", [[<cmd>lua require("kyoh86.conf.todo").open_note()<cr>]], { remap = false, desc = "作業メモを編集する" })
local filename = "~/.local/state/to" .. "do.md"
return {
  open_note = function()
    local winids = vim.fn.win_findbuf(vim.fn.bufnr(filename))
    local winid = -1
    if #winids == 0 then
      vim.cmd([[topleft new ]] .. filename)
      winid = vim.fn.bufwinid(filename)
    else
      winid = winids[1]
      vim.api.nvim_set_current_win(winid)
      vim.cmd([[wincmd K]])
    end
    local line_count = vim.api.nvim_buf_line_count(0)
    vim.api.nvim_win_set_height(winid, line_count + 1)
  end,
}
