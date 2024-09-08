local volaterm = require("kyoh86.lib.volatile_terminal")

local function save_mode()
  if vim.b.volaterm == 1 then
    vim.b.volaterm_mode = vim.fn.mode()
    vim.cmd.stopinsert()
  end
end

local function restore_mode()
  if vim.b.volaterm == 1 and vim.b.volaterm_mode == "t" then
    vim.cmd.startinsert()
  end
end

local group = vim.api.nvim_create_augroup("kyoh86-conf-volatile-terminal-mode", {})
vim.api.nvim_create_autocmd("BufLeave", {
  pattern = "term://*",
  group = group,
  callback = save_mode,
})
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "term://*",
  group = group,
  callback = restore_mode,
})
vim.api.nvim_create_autocmd("TermOpen", {
  group = group,
  pattern = "term://*",
  callback = function()
    if vim.b.volaterm == 1 then
      vim.cmd.startinsert()
    end
  end,
})

local f = require("kyoh86.lib.func")
vim.keymap.set("n", "tx", f.bind_all(volaterm.split, 0, {}), { remap = false, silent = true, desc = "open a terminal in a splitted window" })
vim.keymap.set("n", "tv", f.bind_all(volaterm.split, 0, { vertical = true }), { remap = false, silent = true, desc = "open a terminal in a vertical-splitted window" })
vim.keymap.set("n", "tcx", f.bind_all(volaterm.split, 0, {}, { cwd = vim.fn.expand("%:p:h") }), { remap = false, silent = true, desc = "open a terminal in a splitted window from current working directory" })
vim.keymap.set("n", "tcv", f.bind_all(volaterm.split, 0, { vertical = true }, { cwd = vim.fn.expand("%:p:h") }), { remap = false, silent = true, desc = "open a terminal in a vertical-splitted window from current working directory" })
