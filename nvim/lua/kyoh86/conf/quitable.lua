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

local function is_floating_win(winid)
  return vim.api.nvim_win_get_config(winid).relative ~= ""
end

local function normal_window_count()
  local count = 0
  for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
      if not is_floating_win(winid) then
        count = count + 1
      end
    end
  end
  return count
end

local function current_quit_exits_nvim()
  if is_floating_win(vim.api.nvim_get_current_win()) then
    return false
  end
  return normal_window_count() <= 1
end

local function guard_nvim_exit(force, whole_editor)
  if force then
    return false
  end
  if tmux_pane_count() <= 1 then
    return false
  end
  if not whole_editor and not current_quit_exits_nvim() then
    return false
  end
  vim.notify("tmux に他の pane があるので Neovim の終了を止めました (:q! で強制終了)", vim.log.levels.WARN)
  return true
end

local function guarded_quit(opts)
  if guard_nvim_exit(opts.bang, false) then
    return
  end
  vim.cmd.quit({ bang = opts.bang })
end

local function guarded_quitall(opts)
  if guard_nvim_exit(opts.bang, true) then
    return
  end
  vim.cmd.quitall({ bang = opts.bang })
end

local function guarded_force_quit()
  if guard_nvim_exit(false, false) then
    return
  end
  vim.cmd.quit({ bang = true })
end

local function guarded_writequit(opts)
  if guard_nvim_exit(opts.bang, false) then
    return
  end
  vim.cmd.writequit({ bang = opts.bang })
end

local function guarded_xit(opts)
  if guard_nvim_exit(opts.bang, false) then
    return
  end
  vim.cmd.xit({ bang = opts.bang })
end

vim.api.nvim_create_user_command("Kyoh86Quit", guarded_quit, { bang = true })
vim.api.nvim_create_user_command("Kyoh86QuitAll", guarded_quitall, { bang = true })
vim.api.nvim_create_user_command("Kyoh86WriteQuit", guarded_writequit, { bang = true })
vim.api.nvim_create_user_command("Kyoh86Xit", guarded_xit, { bang = true })
vim.cmd([[cnoreabbrev <expr> q getcmdtype() == ':' && getcmdline() ==# 'q' ? 'Kyoh86Quit' : 'q']])
vim.cmd([[cnoreabbrev <expr> quit getcmdtype() == ':' && getcmdline() ==# 'quit' ? 'Kyoh86Quit' : 'quit']])
vim.cmd([[cnoreabbrev <expr> qa getcmdtype() == ':' && getcmdline() ==# 'qa' ? 'Kyoh86QuitAll' : 'qa']])
vim.cmd([[cnoreabbrev <expr> qall getcmdtype() == ':' && getcmdline() ==# 'qall' ? 'Kyoh86QuitAll' : 'qall']])
vim.cmd([[cnoreabbrev <expr> wq getcmdtype() == ':' && getcmdline() ==# 'wq' ? 'Kyoh86WriteQuit' : 'wq']])
vim.cmd([[cnoreabbrev <expr> x getcmdtype() == ':' && getcmdline() ==# 'x' ? 'Kyoh86Xit' : 'x']])
vim.keymap.set("n", "ZQ", guarded_force_quit, { remap = false })
vim.keymap.set("n", "ZZ", function()
  guarded_xit({ bang = false })
end, { remap = false })

local au = require("kyoh86.lib.autocmd")
au.group("kyoh86.conf.quitable", true):hook("ExitPre", {
  callback = quit_empty_buffers,
})
