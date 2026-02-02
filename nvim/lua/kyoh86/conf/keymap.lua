local M = {}

-- see :help keycodes
local specials = {
  Nul = "󰟢", -- Zero
  BS = "󰁮", -- Backspace
  Tab = "󰌒", -- Tab
  NL = "󰌑", -- Linefeed
  CR = "󰌑", -- Carriage return
  Esc = "󱊷", -- Escape
  Space = "󱁐", -- Space
  Del = "󰅂", -- Delete
  Up = "󰁝", -- Up
  Down = "󰁅", -- Down
  Left = "󰁍", -- Left
  Right = "󰁔", -- Right

  Home = "󰘀", -- Home                            *home*
  End = "󰘁", -- End                             *end*
  PageUp = "󰍝", -- Page-up                         *page_up* *page-up*
  PageDown = "󰍠", -- Page-down                       *page_down* *page-down*

  C = "󰘴", -- Control <C-..>
  S = "󰘶", -- Shift <S-..>
  M = "󰘬", -- Meta/Alt <M-..>
  D = "󰘳", -- Command/Super <D-..>

  F1 = "󱊫",
  F2 = "󱊬",
  F3 = "󱊭,",
  F4 = "󱊮",
  F5 = "󱊯",
  F6 = "󱊰",
  F7 = "󱊱",
  F8 = "󱊲",
  F9 = "󱊳",
  F10 = "󱊴",
  F11 = "󱊵",
  F12 = "󱊶",
}

--- @class kyoh86.conf.KeymapDescription
--- @field buf boolean
--- @field mode string
--- @field lhs string
--- @field lh_chars string
--- @field desc string

--- @class kyoh86.conf.KeymapDescriptionWidth
--- @field mode integer
--- @field lhs integer
--- @field lh_chars integer
--- @field desc integer

--- @class kyoh86.conf.KeymapList
--- @field width kyoh86.conf.KeymapDescriptionWidth
--- @field items kyoh86.conf.KeymapDescription[]

--- @class kyoh86.conf.KeymapListOpts
--- @field buf boolean
--- @field global boolean
--- @field plug boolean
--- @field source boolean
--- @field mouse boolean

local function decorate_special_key(key)
  local d = specials[key]
  if d == nil then
    return key
  end
  return d
end

--- @param char string
--- @return string
local function decorate_char(char)
  if string.sub(char, 1, 1) ~= "<" or string.sub(char, -1, -1) ~= ">" then
    return char
  end
  local keys = vim.fn.split(string.sub(char, 2, -2), "-", false)
  if #keys == 1 then
    return decorate_special_key(keys[1])
  end
  local decorates = {}
  for i, key in ipairs(keys) do
    if #key == 1 and i == #keys then -- C-やS-などの1文字は最後のキーとしては装飾しない（CTRL+S等の場合、最後の文字がこれらの装飾キー表記に衝突するのを避ける）
      table.insert(decorates, key)
    else
      local d = decorate_special_key(key)
      table.insert(decorates, d)
    end
  end
  local ret = table.concat(decorates, "")
  return ret
end

--- @param code string
--- @return string
local function decorate_lhs(code)
  local chars = vim.fn.split(code, [[\(<[^>]\+>\)\@<=\|\(<[^>]\+>\)\@=]], false)
  return table.concat(vim.iter(chars):map(decorate_char):totable(), "")
end

--- @param dest kyoh86.conf.KeymapList
--- @param item vim.api.keyset.get_keymap
--- @param opts kyoh86.conf.KeymapListOpts
local function aggr_keymap(dest, item, opts)
  if item.abbr == 1 then
    return dest
  end
  if not opts.plug and string.sub(item.lhs, 1, 6) == "<Plug>" then
    return dest
  end
  if not opts.source and string.sub(item.lhs, 1, 5) == "<SNR>" then
    return dest
  end
  if not opts.mouse and string.find(item.lhs, "Mouse>") ~= nil then
    return dest
  end
  if item.mode ~= nil then
    dest.width.mode = math.max(dest.width.mode, #item.mode)
  end
  local lh_chars = ""
  if item.lhs ~= nil then
    dest.width.lhs = math.max(dest.width.lhs, #item.lhs)
    lh_chars = decorate_lhs(item.lhs or "")
    dest.width.lh_chars = math.max(dest.width.lh_chars, vim.fn.strdisplaywidth(lh_chars))
  end
  if item.desc ~= nil then
    dest.width.desc = math.max(dest.width.desc, #item.desc)
  end
  table.insert(dest.items, {
    buf = item.buffer == 1,
    mode = item.mode or "",
    lhs = item.lhs or "",
    lh_chars = lh_chars,
    desc = item.desc or "",
  })
  return dest
end

local function padright(s, width)
  local w = vim.fn.strdisplaywidth(s)
  return s .. string.rep(" ", width - w)
end

--- @param list kyoh86.conf.KeymapList
local function get_window_size(list)
  local height = math.min(#list.items + 1, math.max(1, math.floor(vim.o.lines * 0.9)))
  local width = math.min(list.width.mode + list.width.lh_chars + list.width.desc + 5, math.max(20, math.floor(vim.o.columns * 0.9)))
  return {
    height = height,
    width = width,
    row = math.floor((vim.o.lines - height) / 2 - 1),
    col = math.floor((vim.o.columns - width) / 2),
  }
end

function M.list_keymaps(opts)
  opts = vim.tbl_extend("force", {
    buf = true,
    global = true,
    plug = false,
    source = false,
    mouse = false,
  }, opts or {})
  local maps = {}
  local ok, tmp = pcall(vim.api.nvim_buf_get_keymap, 0, "n")
  if ok then
    vim.list_extend(maps, tmp)
  end
  vim.list_extend(maps, vim.api.nvim_get_keymap("n"))

  --- @type kyoh86.conf.KeymapList
  local list = {
    width = { mode = 0, lhs = 0, lh_chars = 0, desc = 0 },
    items = {},
  }
  for _, map in ipairs(maps) do
    aggr_keymap(list, map, opts)
  end

  local size = get_window_size(list)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = true

  local format = string.format("%%s %%-%ds %%s %%-%ds", list.width.mode, list.width.desc)
  vim.api.nvim_buf_set_lines(
    buf,
    0,
    -1,
    false,
    vim
      .iter(list.items)
      :map(function(item)
        return string.format(format, item.buf and "@" or " ", item.mode, padright(item.lh_chars, list.width.lh_chars), item.desc)
      end)
      :totable()
  )

  vim.bo[buf].modifiable = false

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = size.row,
    col = size.col,
    width = size.width,
    height = size.height,
    style = "minimal",
    border = "single",
  })

  local au = require("kyoh86.lib.autocmd")
  local gr = au.buf_group(buf, "kyoh86.conf.keymap")
  gr:hook("VimResized", {
    callback = function()
      local s = get_window_size(list)
      vim.api.nvim_win_set_config(win, {
        relative = "editor",
        row = s.row,
        col = s.col,
        width = s.width,
        height = s.height,
        style = "minimal",
        border = "single",
      })
    end,
  })

  local win_close = require("kyoh86.lib.func").vind_all(vim.api.nvim_win_hide, win)
  gr:hook("WinLeave", { callback = win_close })
  vim.keymap.set("n", "q", win_close, { buffer = buf })
  vim.keymap.set("n", "<Esc>", win_close, { buffer = buf })

  return buf, win
end

vim.keymap.set("n", "<leader>?", function()
  require("kyoh86.conf.keymap").list_keymaps({})
end, {})

return M
