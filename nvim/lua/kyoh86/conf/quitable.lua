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

local function tmux_pane_count()
  if not vim.env.TMUX then
    return 0
  end
  local result = vim.system({ "tmux", "list-panes", "-F", "#{pane_id}" }, { text = true }):wait()
  if result.code ~= 0 then
    return 0
  end
  local count = 0
  for line in vim.gsplit(result.stdout, "\n", { plain = true, trimempty = true }) do
    if line ~= "" then
      count = count + 1
    end
  end
  return count
end

local function should_guard_nvim_exit()
  if vim.v.exitreason ~= "quit" then
    return false
  end
  if tmux_pane_count() <= 1 then
    return false
  end
  return true
end

local function guard_nvim_exit()
  if not should_guard_nvim_exit() then
    return
  end

  vim.cmd("silent keepalt enew!")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].swapfile = false
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "quit guarded by tmux panes" })
  vim.schedule(function()
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end)
  vim.notify("tmux に他の pane があるので Neovim の終了を止めました", vim.log.levels.WARN)
end

local au = require("kyoh86.lib.autocmd")
local group = au.group("kyoh86.conf.quitable", true)
group:hook("ExitPre", {
  callback = quit_empty_buffers,
})
group:hook("ExitPre", {
  callback = guard_nvim_exit,
})
