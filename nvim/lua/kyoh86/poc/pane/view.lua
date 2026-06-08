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
  vim.api.nvim_set_hl(0, "LayoutPareditFirstFill", { bg = "#c2c2f2" })
  vim.api.nvim_set_hl(0, "LayoutPareditSecondFill", { bg = "#dadaf7" })
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

local function open_fill(state, rect, hl)
  if not rect then
    return nil
  end
  local row = math.max(0, rect.row)
  local col = math.max(0, rect.col)
  local width = math.max(1, rect.width)
  local height = math.max(1, rect.height)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(
    buf,
    0,
    -1,
    false,
    vim.tbl_map(function()
      return string.rep(" ", width)
    end, vim.fn.range(1, height))
  )
  vim.bo[buf].modifiable = false

  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    focusable = false,
    zindex = 190,
    noautocmd = true,
  })
  vim.wo[win].winhighlight = "Normal:" .. hl
  vim.wo[win].winblend = 25
  table.insert(state.floats, win)
  return win
end

---@param state { floats: integer[] }
---@param node kyoh86.lib.pane.window.LiveNode
---@param hl string
local function open_node_fills(state, node, hl)
  for _, item in ipairs(tree.all_nodes(node)) do
    if tree.is_leaf(item.node) then
      open_fill(state, M.node_rect(item.node), hl)
    end
  end
end

---@param state { floats: integer[] }
---@param node kyoh86.lib.pane.window.LiveNode
function M.open_selection(state, node)
  if tree.is_leaf(node) then
    open_node_fills(state, node, "LayoutPareditFirstFill")
    return
  end

  open_node_fills(state, node.first, "LayoutPareditFirstFill")
  open_node_fills(state, node.second, "LayoutPareditSecondFill")
end

return M
