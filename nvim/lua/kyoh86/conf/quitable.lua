--- 空バッファを無視して閉じる
local wipeout_queue = {}

local function enqueue()
  if require("kyoh86.lib.initial_buffer").current() then
    table.insert(wipeout_queue, vim.api.nvim_get_current_buf())
  end
end

local function quit_empty_buffers()
  wipeout_queue = {}
  local cur = vim.fn.bufnr()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    vim.api.nvim_buf_call(b, enqueue)
  end
  vim.cmd.buffer({ cur, bang = true })

  for _, b in ipairs(wipeout_queue) do
    vim.cmd.bwipeout({ b, bang = true })
  end
end

local au = require("kyoh86.lib.autocmd")
au.group("kyoh86.conf.quitable", true):hook("ExitPre", {
  callback = quit_empty_buffers,
})
