local M = {}

local pathlib = require("kyoh86.lib.pane_layout.path")
---@alias kyoh86.lib.pane_layout.window.Layout vim.fn.winlayout.leaf | vim.fn.winlayout.branch

---vim.fn.winlayout() の結果をバイナリツリーに正規化
---@param layout kyoh86.lib.pane_layout.window.Layout
---@return kyoh86.lib.pane_layout.window.Layout
local function normalize_to_binary(layout)
  if layout[1] == "leaf" then
    return layout
  end

  local axis = layout[1] -- "row" or "col"
  local children = layout[2]

  if #children == 0 then
    return layout
  end
  if #children == 1 then
    return normalize_to_binary(children[1])
  end
  if #children == 2 then
    return { axis, {
      normalize_to_binary(children[1]),
      normalize_to_binary(children[2]),
    } }
  end

  -- 3つ以上の場合は左結合で畳み込む
  local result = normalize_to_binary(children[1])
  for i = 2, #children do
    result = {
      axis,
      {
        result,
        normalize_to_binary(children[i] --[[@as kyoh86.lib.pane_layout.window.Layout]]),
      },
    }
  end
  return result
end

---現在のタブのWindowLayoutをバイナリツリーに正規化して取得する
---NOTE:「現在のタブ」が存在しないことはないため、emptyを否定できる
---@return kyoh86.lib.pane_layout.window.Layout
function M.get_layout()
  return normalize_to_binary(vim.fn.winlayout() --[[@as kyoh86.lib.pane_layout.window.Layout]])
end

---@param layout kyoh86.lib.pane_layout.window.Layout
---@param win integer
---@param path kyoh86.lib.pane_layout.Path
---@return kyoh86.lib.pane_layout.Path
local function get_path(layout, win, path)
  if layout[1] == "leaf" then
    if layout[2] == win then
      return path
    else
      return {}
    end
  end
  local children = layout[2]
  if #children == 0 then
    if layout[2] == win then
      return path
    else
      return {}
    end
  end
  if #children == 1 then
    return get_path(children[1], win, pathlib.child(path, 1))
  end
  if #children == 2 then
    local first = get_path(children[1], win, pathlib.child(path, 1))
    if #first > 0 then
      return first
    end
    local second = get_path(children[2], win, pathlib.child(path, 2))
    if #second > 0 then
      return second
    end
    return {}
  end
  return {}
end

---@param layout kyoh86.lib.pane_layout.window.Layout
---@param win integer
---@return kyoh86.lib.pane_layout.Path
function M.get_path(layout, win)
  return get_path(layout, win, {})
end

---@param layout kyoh86.lib.pane_layout.window.Layout
---@param path kyoh86.lib.pane_layout.Path
---@return integer
function M.at(layout, path)
  if layout[1] == "leaf" then
    return layout[2] --[[@as integer]]
  end
  if #path == 0 then
    return -1
  end

  local children = layout[2]
  local root, next = pathlib.digg(path)
  if root == 1 then
    return M.at(children[1], next)
  end
  if root == 2 then
    return M.at(children[2], next)
  end
  return -1
end

return M
