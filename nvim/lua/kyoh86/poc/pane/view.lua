local tree = require("kyoh86.poc.pane.tree")

local M = {}

---@class kyoh86.poc.pane.Rect
---@field row integer
---@field col integer
---@field width integer
---@field height integer

---@param state { floats: integer[] }
function M.close_floats(state)
  for _, win in ipairs(state.floats) do
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
  state.floats = {}
end

function M.ensure_highlights()
  vim.api.nvim_set_hl(0, "LayoutPareditSelection", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "LayoutPareditBorder", { fg = "#ff8bd1", bg = "NONE" })
  vim.api.nvim_set_hl(0, "LayoutPareditTitle", { fg = "#101217", bg = "#ff8bd1", bold = true })
  vim.api.nvim_set_hl(0, "LayoutPareditFirstBorder", { fg = "#c2c2f2", bg = "NONE" })
  vim.api.nvim_set_hl(0, "LayoutPareditFirstTitle", { fg = "#101217", bg = "#c2c2f2", bold = true })
  vim.api.nvim_set_hl(0, "LayoutPareditSecondBorder", { fg = "#dadaf7", bg = "NONE" })
  vim.api.nvim_set_hl(0, "LayoutPareditSecondTitle", { fg = "#101217", bg = "#dadaf7", bold = true })
end

---@param a? kyoh86.poc.pane.Rect
---@param b? kyoh86.poc.pane.Rect
---@return kyoh86.poc.pane.Rect|nil
local function union_rect(a, b)
  if not a then
    return b
  end
  if not b then
    return a
  end
  local row = math.min(a.row, b.row)
  local col = math.min(a.col, b.col)
  local bottom = math.max(a.row + a.height, b.row + b.height)
  local right = math.max(a.col + a.width, b.col + b.width)
  return {
    row = row,
    col = col,
    width = right - col,
    height = bottom - row,
  }
end

---@param win integer
---@return kyoh86.poc.pane.Rect|nil
local function win_rect(win)
  if not vim.api.nvim_win_is_valid(win) then
    return nil
  end
  local pos = vim.api.nvim_win_get_position(win)
  local width = vim.api.nvim_win_get_width(win)
  local height = vim.api.nvim_win_get_height(win)
  return {
    row = pos[1],
    col = pos[2],
    width = width,
    height = height,
  }
end

---@param node kyoh86.lib.pane.window.LiveNode
---@return kyoh86.poc.pane.Rect|nil
function M.node_rect(node)
  local rect = nil
  for _, win in ipairs(tree.leaves(node)) do
    rect = union_rect(rect, win_rect(win))
  end
  return rect
end

local function open_line(state, row, col, width, height, lines, hl, zindex)
  if width <= 0 or height <= 0 then
    return nil
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    focusable = false,
    zindex = zindex or 200,
    noautocmd = true,
  })
  vim.wo[win].winhighlight = hl
  vim.wo[win].winblend = 0
  table.insert(state.floats, win)
  return win
end

local function truncate_width(text, width)
  if width <= 0 then
    return ""
  end
  local out = vim.fn.strcharpart(text, 0, width)
  local display = vim.fn.strdisplaywidth(out)
  if display < width then
    out = out .. string.rep(" ", width - display)
  end
  return out
end

---@param state { floats: integer[] }
---@param config { winhighlight: string }
---@param rect? kyoh86.poc.pane.Rect
---@param title? string
---@param hl? string
function M.open_frame(state, config, rect, title, hl)
  if not rect then
    return nil
  end

  local row = math.max(0, rect.row)
  local col = math.max(0, rect.col)
  local width = math.max(2, rect.width)
  local height = math.max(2, rect.height)
  local right = col + width - 1
  local bottom = row + height - 1

  local border_hl = hl or config.winhighlight
  local top_text = "╭" .. string.rep("─", math.max(0, width - 2)) .. "╮"
  if title and title ~= "" and width > 6 then
    local label = truncate_width(title, width - 4)
    top_text = "╭" .. label .. string.rep("─", math.max(0, width - 2 - vim.fn.strdisplaywidth(label))) .. "╮"
  end
  local bottom_text = "╰" .. string.rep("─", math.max(0, width - 2)) .. "╯"

  open_line(state, row, col, width, 1, { top_text }, border_hl, 210)
  open_line(state, bottom, col, width, 1, { bottom_text }, border_hl, 210)

  if height > 2 then
    local side_lines = {}
    for _ = 1, height - 2 do
      table.insert(side_lines, "│")
    end
    open_line(state, row + 1, col, 1, height - 2, side_lines, border_hl, 210)
    open_line(state, row + 1, right, 1, height - 2, side_lines, border_hl, 210)
  end
end

---@param state { floats: integer[] }
---@param config { winhighlight: string }
---@param node kyoh86.lib.pane.window.LiveNode
---@param title_prefix string
---@param hl string
local function open_node_frames(state, config, node, title_prefix, hl)
  for _, item in ipairs(tree.all_nodes(node)) do
    if tree.is_leaf(item.node) then
      M.open_frame(state, config, M.node_rect(item.node), " " .. title_prefix .. " " .. tree.compact(item.node) .. " ", hl)
    end
  end
end

---@param state { floats: integer[] }
---@param config { winhighlight: string }
---@param node kyoh86.lib.pane.window.LiveNode
function M.open_selection(state, config, node)
  if tree.is_leaf(node) then
    open_node_frames(state, config, node, "FIRST", "Normal:LayoutPareditSelection,FloatBorder:LayoutPareditFirstBorder,FloatTitle:LayoutPareditFirstTitle")
    return
  end

  open_node_frames(state, config, node.first, "FIRST", "Normal:LayoutPareditSelection,FloatBorder:LayoutPareditFirstBorder,FloatTitle:LayoutPareditFirstTitle")
  open_node_frames(state, config, node.second, "SECOND", "Normal:LayoutPareditSelection,FloatBorder:LayoutPareditSecondBorder,FloatTitle:LayoutPareditSecondTitle")
end

return M
