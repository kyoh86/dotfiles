local M = {}

local keyopt = { nowait = true, buffer = true }

function M.operate()
  if vim.opt.filetype:get() ~= "fern" then
    return
  end
  vim.b.my_fern_mode = "operate"

  vim.keymap.set("n", "<space>", "<plug>(fern-action-mark:toggle)", keyopt)
  vim.keymap.set("n", "<c-s-space>", "<plug>(fern-action-mark:clear)", keyopt)
  vim.keymap.set("n", "<esc>", "<plug>(fern-action-cancel)<plug>(fern-action-mark:clear)<cmd>lua require('kyoh86.plug.fern.mode').view(v:false)<cr>", keyopt)
  vim.keymap.set("n", "N", "<plug>(fern-action-new-path)", keyopt)
  vim.keymap.set("n", "C", "<plug>(fern-action-copy)", keyopt)
  vim.keymap.set("n", "M", "<plug>(fern-action-move)", keyopt)
  vim.keymap.set("n", "D", "<plug>(fern-action-remove)", keyopt)
  vim.keymap.set("n", "R", "<plug>(fern-action-rename)", keyopt)

  vim.notify("Changed to operation mode", vim.log.levels.WARN)

  vim.cmd([[doautocmd User MyFernModeChanged]])
end

function M.view(init)
  if vim.opt.filetype:get() ~= "fern" then
    return
  end
  vim.b.my_fern_mode = "view"

  if init then
    kyoh86.fa.fern.action.call("mark:clear")
  end

  vim.keymap.del("n", "<space>")
  vim.keymap.del("n", "<c-s-space>")
  vim.keymap.del("n", "<esc>", "<plug>(fern-action-cancel)", keyopt)
  vim.keymap.del("n", "N")
  vim.keymap.del("n", "C")
  vim.keymap.del("n", "M")
  vim.keymap.del("n", "D")
  vim.keymap.del("n", "R")

  vim.notify("Changed to viewing mode", vim.log.levels.WARN)

  vim.cmd([[doautocmd User MyFernModeChanged]])
end

function M.toggle()
  if vim.opt.filetype:get() ~= "fern" then
    return
  end
  local mode = vim.tbl_get(vim.b, "my_fern_mode")
  if mode ~= "operate" then
    M.operate()
  else
    M.view(false)
  end
end

function M.setup()
  vim.keymap.set("n", "!", "<plug>(fern-action-hidden:toggle)", keyopt)
  vim.keymap.set("n", "<c-r>", "<plug>(fern-action-reload:cursor)", keyopt)
  vim.keymap.set("n", "<c-s-r>", "<plug>(fern-action-reload:all)", keyopt)
  vim.keymap.set("n", ">", "<plug>(fern-action-expand:in)", keyopt)
  vim.keymap.set("n", "<", "<plug>(fern-action-collapse)", keyopt)
  vim.keymap.set("n", "-", "<plug>(fern-action-leave)", keyopt)
  vim.keymap.set("n", "+", "<plug>(fern-action-enter)", keyopt)
  vim.keymap.set("n", "<leader>x", "<plug>(fern-action-open:above)", keyopt)
  vim.keymap.set("n", "<leader>h", "<plug>(fern-action-open:above)", keyopt)
  vim.keymap.set("n", "<leader>v", "<plug>(fern-action-open:left)", keyopt)
  vim.keymap.set("n", "<cr>", "<plug>(fern-action-open-or-expand)", keyopt)
  vim.keymap.set("n", "<c-l>", "<plug>(fern-action-redraw)", keyopt)
  vim.keymap.set("n", "y", "<plug>(fern-action-yank:bufname)", keyopt)
  vim.keymap.set("n", "<c-g>", "<plug>(fern-action-cda", keyopt) -- hint: 'g'oto dir
  vim.keymap.set("n", "<c-/>", "<plug>(fern-action-include)", keyopt)
  vim.keymap.set("n", "<c-x>", M.toggle, keyopt)
end

return M
