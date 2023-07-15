local M = {}

--- Terminalを気軽に開いたり閉じたりする
function M.open(opts)
  opts = vim.tbl_extend("keep", opts or vim.empty_dict(), {
    exec = vim.o.shell,
  })
  local bufnr = vim.api.nvim_get_current_buf()
  vim.b[bufnr].volaterm = 1
  vim.b[bufnr].volaterm_mode = "t"
  if not opts.keep then
    opts = vim.tbl_extend("keep", opts, {
      on_exit = function()
        pcall(vim.api.nvim_buf_delete, bufnr, { force = true, unload = false })
      end,
    })
  end
  -- 終了時にバッファを消すterminalを開く
  vim.fn.termopen(opts.exec, opts)
end

function M.split(size, mods, opts)
  -- 指定方向に画面分割
  vim.cmd(mods .. " " .. "new")
  M.open(opts)
  -- 指定方向にresize
  if size ~= 0 then
    vim.cmd(mods .. " resize " .. size)
  end
end

return M
