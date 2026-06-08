-- pane.lua
-- ペインレイアウトをツリー構造から構築するライブラリ

local M = {}

-- レイアウトツリーの構造:
-- {
--   kind = "pane",      -- リーフ（ペイン）
--   buffer = number,    -- bufnr (省略時は空バッファ)
--   width = number,     -- paneの幅
--   height = number,    -- paneの高さ
-- }
-- または
-- {
--   kind = "row" | "col",  -- 分割方向 (row=左右, col=上下)
--   first = Node,       -- 左/上の子
--   second = Node,      -- 右/下の子
-- }

---@class kyoh86.lib.pane.Layout
---@field root kyoh86.lib.pane.Node
---@field cur kyoh86.lib.pane.Path

---@alias kyoh86.lib.pane.Node kyoh86.lib.pane.LeafNode|kyoh86.lib.pane.SplitNode

---@class kyoh86.lib.pane.LeafNode
---@field kind "pane" リーフ（ペイン）
---@field buffer number bufnr (省略時は空バッファ)
---@field width number paneの幅
---@field height number paneの高さ

---@class kyoh86.lib.pane.SplitNode
---@field kind "row"|"col" 分割方向 (row=左右, col=上下)
---@field first kyoh86.lib.pane.Node 左/上の子
---@field second kyoh86.lib.pane.Node 右/下の子

---レイアウトを適用
---@param layout kyoh86.lib.pane.Layout
function M.apply(layout)
  vim.cmd("only") -- リセット
  local win = vim.api.nvim_get_current_win()

  require("kyoh86.lib.pane.apply").apply(layout.root, win)

  local window = require("kyoh86.lib.pane.window")
  local old_layout = window.get_layout()
  local new_win = window.at(old_layout, layout.cur)
  if new_win > 0 then
    vim.api.nvim_set_current_win(new_win)
  end
end

-- LiveNodeを保存・apply用のレイアウトツリーに変換
---@param layout kyoh86.lib.pane.window.LiveNode
---@return kyoh86.lib.pane.Node
local function convert_node(layout)
  if layout.kind == "pane" then
    return {
      kind = "pane",
      buffer = layout.buffer,
      width = layout.width,
      height = layout.height,
    }
  end

  return {
    kind = layout.kind,
    first = convert_node(layout.first),
    second = convert_node(layout.second),
  }
end

--- 現在のレイアウトを取得
--- @return kyoh86.lib.pane.Layout レイアウトツリー
function M.get()
  local window = require("kyoh86.lib.pane.window")
  local layout = window.get_layout()
  local tree = window.get_tree(layout)
  return { cur = window.get_path(layout, vim.api.nvim_get_current_win()), root = convert_node(tree) }
end

-- 現在のレイアウトをJSONとして現在のバッファに出力（内容は全て置換）
function M.dump()
  local layout = M.get()
  local json = vim.fn.json_encode(layout)
  local buf = vim.api.nvim_get_current_buf()

  -- バッファの内容を全て削除
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

  -- JSONを行として追加
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { json })
end

-- 現在のバッファの内容をJSONとして読み込んで適用
function M.load()
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  if #lines == 0 then
    vim.notify("Buffer is empty", vim.log.levels.ERROR)
    return
  end

  local json = table.concat(lines, "\n")
  local ok, layout = pcall(vim.fn.json_decode, json)

  if not ok then
    vim.notify("Failed to parse JSON: " .. tostring(layout), vim.log.levels.ERROR)
    return
  end

  M.apply(layout)
end

return M
