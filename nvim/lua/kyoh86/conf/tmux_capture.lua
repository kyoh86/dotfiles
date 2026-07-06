local tmux = require("kyoh86.lib.tmux")

local M = {}

local function split_lines(text)
  local lines = vim.split(text or "", "\n", { plain = true })
  if #lines > 1 and lines[#lines] == "" then
    table.remove(lines)
  end
  if #lines == 0 then
    return { "" }
  end
  return lines
end

local function capture_name(data)
  local pane = data.pane or "pane"
  local timestamp = os.date("%Y%m%dT%H%M%S")
  return ("tmux://%s/%s-%s"):format(pane, timestamp, vim.uv.hrtime())
end

local function decode_printable_escapes(text)
  return (text or ""):gsub("\\033", "\27"):gsub("\\027", "\27"):gsub("\\x1[bB]", "\27"):gsub("\\e", "\27"):gsub("%^%[", "\27")
end

local function has_ansi_escape(text)
  text = text or ""
  return text:find("\27", 1, true) ~= nil or text:find("\\033", 1, true) ~= nil or text:find("\\027", 1, true) ~= nil or text:find("\\x1b", 1, true) ~= nil or text:find("\\x1B", 1, true) ~= nil or text:find("\\e", 1, true) ~= nil or text:find("^[", 1, true) ~= nil
end

local function append_unique(list, value)
  if list[#list] ~= value then
    table.insert(list, value)
  end
end

local function strip_ansi(text)
  return (text or ""):gsub("\27%][^\7]*\7", ""):gsub("\27%][^\27]*\27\\", ""):gsub("\27%[[%d;?]*[%a]", "")
end

local function command_lines_from_ansi(text)
  text = decode_printable_escapes(text):gsub("\r\n", "\n")

  local lines = {}
  local line = 1
  local index = 1
  while index <= #text do
    local char = text:sub(index, index)
    if char == "\n" then
      line = line + 1
      index = index + 1
    elseif char == "\27" and text:sub(index + 1, index + 1) == "]" then
      local bel = text:find("\7", index + 2, true)
      local st = text:find("\27\\", index + 2, true)
      local finish
      if bel ~= nil and (st == nil or bel < st) then
        finish = bel
      else
        finish = st
      end
      if finish == nil then
        index = index + 1
      else
        local sequence = text:sub(index + 2, finish - 1)
        if sequence:match("^133;B") then
          append_unique(lines, line)
        end
        index = finish + (finish == st and 2 or 1)
      end
    else
      index = index + 1
    end
  end

  if #lines > 0 then
    return lines
  end

  for lnum, ltext in ipairs(vim.split(strip_ansi(text), "\n", { plain = true })) do
    if ltext:match("^%$%s") then
      table.insert(lines, lnum)
    end
  end
  return lines
end

local function command_lines_from_lines(lines)
  local command_lines = {}
  for lnum, ltext in ipairs(lines) do
    if ltext:match("^%$%s") then
      table.insert(command_lines, lnum)
    end
  end
  return command_lines
end

local function jump_command(delta)
  local lines = vim.b.tmux_capture_command_lines or {}
  if #lines == 0 then
    return
  end

  local current = vim.api.nvim_win_get_cursor(0)[1]
  local target = nil
  if delta < 0 then
    for index = #lines, 1, -1 do
      if lines[index] < current then
        target = lines[index]
        break
      end
    end
  else
    for _, lnum in ipairs(lines) do
      if lnum > current then
        target = lnum
        break
      end
    end
  end

  if target == nil then
    return
  end
  vim.api.nvim_win_set_cursor(0, { target, 0 })
  vim.cmd.normal({ "zt", bang = true })
end

local function setup_command_scroll(buf, command_lines)
  vim.b[buf].tmux_capture_command_lines = command_lines
  vim.keymap.set("n", "<Up>", function()
    jump_command(-1)
  end, { buffer = buf, remap = false, desc = "前の tmux コマンドへ移動" })
  vim.keymap.set("n", "<Down>", function()
    jump_command(1)
  end, { buffer = buf, remap = false, desc = "次の tmux コマンドへ移動" })
end

local function open_ansi(data)
  vim.cmd.tabnew()
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buflisted = true
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "tmux-capture"
  vim.api.nvim_buf_set_name(buf, capture_name(data))

  local chan = vim.api.nvim_open_term(buf, {})
  local text = decode_printable_escapes(data.text):gsub("\r\n", "\n"):gsub("\n", "\r\n")
  vim.api.nvim_chan_send(chan, text)
  pcall(vim.fn.chanclose, chan)
  setup_command_scroll(buf, command_lines_from_ansi(data.text))

  if data.cwd ~= nil and data.cwd ~= "" then
    pcall(vim.cmd.lcd, vim.fn.fnameescape(data.cwd))
  end

  vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(buf), 0 })
  tmux.focus_nvim_pane()
end

function M.open(data)
  data = data or {}
  if data.format == "ansi" or has_ansi_escape(data.text) then
    open_ansi(data)
    return
  end

  local lines = split_lines(data.text)
  for r = #lines, 1, -1 do
    if lines[r] == "" then
      table.remove(lines, r)
    end
  end

  vim.cmd.tabnew()
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buflisted = true
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "tmux-capture"
  vim.api.nvim_buf_set_name(buf, capture_name(data))

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modified = false
  setup_command_scroll(buf, command_lines_from_lines(lines))

  if data.cwd ~= nil and data.cwd ~= "" then
    pcall(vim.cmd.lcd, vim.fn.fnameescape(data.cwd))
  end

  vim.api.nvim_win_set_cursor(0, { #lines, 0 })
  tmux.focus_nvim_pane()
end

return M
