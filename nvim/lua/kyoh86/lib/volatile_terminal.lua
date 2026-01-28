local M = {}

---@class kyoh86.lib.volaterm.Mods
---@field silent? boolean |:silent|
---@field noautocmd? boolean |:noautocmd|
---@field horizontal? boolean |:horizontal|
---@field vertical? boolean |:vertical|
---@field split? "aboveleft"|"belowright"|"topleft"|"botright" Split modifier string, is an empty string when there's no split modifier See also: |:aboveleft| |:belowright| |:topleft| |:botright|

---@class kyoh86.lib.volaterm.Opts
---@field env? table<string, string?>

--- Terminalを気軽に開いたり閉じたりする
---@param opts? kyoh86.lib.volaterm.Opts
function M.open(opts)
  opts = vim.tbl_extend("keep", opts ~= nil and opts or vim.empty_dict(), {
    term = true,
    exec = vim.o.shell,
  })
  local bufnr = vim.api.nvim_get_current_buf()
  vim.b[bufnr].volaterm = 1
  vim.b[bufnr].volaterm_mode = "t"
  opts.env = vim.tbl_extend("keep", opts.env or vim.empty_dict(), {
    KYOH86_VOLATERM_BUFNR = bufnr,
  })
  if not opts.keep then
    opts = vim.tbl_extend("keep", opts, {
      on_exit = function()
        pcall(vim.api.nvim_buf_delete, bufnr, { force = true, unload = false })
      end,
    })
  end
  if opts.cwd then
    vim.cmd("lcd " .. opts.cwd)
  end
  -- 終了時にバッファを消すterminalを開く
  vim.fn.jobstart(opts.exec, opts)
end

---@param mods? kyoh86.lib.volaterm.Mods
---@param opts? kyoh86.lib.volaterm.Opts
function M.split(size, mods, opts)
  -- 指定方向に画面分割
  vim.cmd({ cmd = "new", mods = mods })
  M.open(opts)
  -- 指定方向にresize
  if size ~= 0 then
    vim.cmd({ cmd = "resize", mods = mods, args = { size } })
  end
end

return M
