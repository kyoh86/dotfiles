--- バッファの中身から検索に引っかかるモノを抽出したバッファを作る
vim.api.nvim_create_user_command("FilterBuf", function(t)
  local number = vim.opt.number:get()
  local list = vim.opt.list:get()
  vim.opt.number = false
  vim.opt.list = false
  local filter = vim.fn.shellescape(t.line1 .. "," .. t.line2 .. "global" .. t.args .. "print")
  vim.cmd("redir @b | silent execute " .. filter .. [[ | redir END]])
  vim.opt.number = number
  vim.opt.list = list
  vim.cmd("silent! " .. t.mods .. " new | silent! " .. "0put! b | $d | 0d")
end, {
  force = true,
  nargs = 1,
  range = "%",
})
