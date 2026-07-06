local function splitdrop(filename, opts)
  vim.validate("filename", filename, "string")
  vim.validate("opts", opts, "table", true, "needs options with a field 'fit'")
  opts = opts or {}

  local bufnr = vim.fn.bufnr(filename)
  local winids = vim.fn.win_findbuf(bufnr)
  local winid = -1
  if #winids == 0 then
    vim.cmd({ cmd = "new", mods = { split = "topleft" }, args = { vim.fn.fnameescape(filename) } })
    winid = vim.fn.bufwinid(filename)
  else
    winid = winids[1]
    vim.api.nvim_set_current_win(winid)
    vim.cmd([[wincmd K]])
  end
  if opts.fit then
    if winid > 0 then -- If the file could not opened ... the fern.vim never opens a buffer named for the directory.
      local line_count = vim.api.nvim_buf_line_count(0)
      vim.api.nvim_win_set_height(winid, line_count + 1)
    end
  end
end

vim.api.nvim_create_user_command("SplitDrop", function(opts)
  splitdrop(opts.args)
end, {
  nargs = 1,
  complete = "file",
})

_G.splitdrop = splitdrop
return splitdrop
