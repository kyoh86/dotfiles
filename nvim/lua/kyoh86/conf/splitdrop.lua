local function splitdrop(filename)
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
  if winid > 0 then -- If the file could not opened ... the fern.vim never opens a buffer named for the directory.
    local line_count = vim.api.nvim_buf_line_count(0)
    vim.api.nvim_win_set_height(winid, line_count + 1)
  end
end
_G.splitdrop = splitdrop
return splitdrop
