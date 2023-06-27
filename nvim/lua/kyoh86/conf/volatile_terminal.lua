--- Terminalを気軽に開いたり閉じたりする
local function open_volaterm(opts)
  opts = vim.tbl_extend("keep", opts or vim.empty_dict(), {
    exec = vim.o.shell,
  })
  local bufnr = vim.api.nvim_get_current_buf()
  vim.b[bufnr].volaterm = 1
  vim.b[bufnr].volaterm_mode = "t"
  opts = vim.tbl_extend("force", opts, {
    on_exit = function()
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true, unload = false })
    end,
  })
  -- 終了時にバッファを消すterminalを開く
  vim.fn.termopen(opts.exec, opts)
end

local function split(size, mods, opts)
  -- 指定方向に画面分割
  vim.cmd(mods .. " " .. "new")
  open_volaterm(opts)
  -- 指定方向にresize
  if size ~= 0 then
    vim.cmd(mods .. " resize " .. size)
  end
end

local function save_mode()
  if vim.b.volaterm == 1 then
    vim.b.volaterm_mode = vim.fn.mode()
    vim.cmd("stopinsert")
  end
end

local function restore_mode()
  if vim.b.volaterm == 1 and vim.b.volaterm_mode == "t" then
    vim.cmd("startinsert")
  end
end

local group = vim.api.nvim_create_augroup("kyoh86-conf-volatile-terminal-mode", {})
vim.api.nvim_create_autocmd("BufLeave", {
  pattern = "term://*",
  group = group,
  callback = function()
    save_mode()
  end,
})
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "term://*",
  group = group,
  callback = function()
    restore_mode()
  end,
})
vim.api.nvim_create_autocmd("TermOpen", {
  group = group,
  pattern = "term://*",
  callback = function()
    if vim.b.volaterm == 1 then
      vim.cmd("startinsert")
    end
  end,
})

vim.keymap.set("n", "tx", function()
  split(0, "")
end, { remap = false, silent = true, desc = "open a terminal in a splitted window" })
vim.keymap.set("n", "tv", function()
  split(0, "vertical")
end, { remap = false, silent = true, desc = "open a terminal in a vertical-splitted window" })
vim.keymap.set("n", "tcx", function()
  split(0, "", { cwd = vim.fn.expand("%:p:h") })
end, { remap = false, silent = true, desc = "open a terminal in a splitted window from current working directory" })
vim.keymap.set("n", "tcv", function()
  split(0, "vertical", { cwd = vim.fn.expand("%:p:h") })
end, { remap = false, silent = true, desc = "open a terminal in a vertical-splitted window from current working directory" })
