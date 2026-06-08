local M = {}

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
---@return string
function M.get_path(layout, win, path)
  if layout[1] == "leaf" then
    if layout[2] == win then
      return path
    else
      return ""
    end
  end
  local children = layout[2]
  if #children == 0 then
    if layout[2] == win then
      return path
    else
      return ""
    end
  end
  if #children == 1 then
    return M.get_path(children[1], win, path .. "/1")
  end
  if #children == 2 then
    local first = M.get_path(children[1], win, path .. "/1")
    if first ~= "" then
      return first
    end
    local second = M.get_path(children[2], win, path .. "/2")
    if second ~= "" then
      return second
    end
    return ""
  end
  return ""
end

---@param layout kyoh86.lib.pane_layout.window.Layout
---@return integer
function M.at(layout, pos)
  if layout[1] == "leaf" then
    return layout[2] --[[@as integer]]
  end
  if pos == "" then
    return -1
  end

  local children = layout[2]
  local next = string.sub(pos, 1, 2)
  if next == "/1" then
    return M.at(children[1], string.sub(pos, 3))
  end
  if next == "/2" then
    return M.at(children[2], string.sub(pos, 3))
  end
  return -1
end

return M
