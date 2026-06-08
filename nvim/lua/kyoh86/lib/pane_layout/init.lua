-- pane_layout.lua
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

---@class Layout
---@field root Node
---@field cur kyoh86.lib.pane_layout.Path

---@alias Node Leaf|Split

---@class Leaf
---@field kind "pane" リーフ（ペイン）
---@field buffer number bufnr (省略時は空バッファ)
---@field width number paneの幅
---@field height number paneの高さ

---@class Split
---@field kind "row"|"col" 分割方向 (row=左右, col=上下)
---@field first Node 左/上の子
---@field second Node 右/下の子

---レイアウトを適用
---@param layout Layout
function M.apply(layout)
  local win = vim.api.nvim_get_current_win()

  require("kyoh86.lib.pane_layout.apply").apply(layout.root, win)

  local window = require("kyoh86.lib.pane_layout.window")
  local old_layout = window.get_layout()
  local new_win = window.at(old_layout, layout.cur)
  if new_win > 0 then
    vim.api.nvim_set_current_win(new_win)
  end
end

-- すべてのウィンドウを閉じて、レイアウトを適用
-- layout: レイアウトツリー
function M.reset_and_apply(layout)
  vim.cmd("only") -- リセット
  M.apply(layout) -- レイアウトを適用
end

-- Neovimのwinlayout形式をユーザー形式に変換
local function convert_node(node)
  if node[1] == "leaf" then
    local winid = node[2]
    local bufnr = vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) or nil
    return {
      kind = "pane",
      buffer = bufnr,
      width = vim.api.nvim_win_get_width(winid),
      height = vim.api.nvim_win_get_height(winid),
    }
  end

  -- axis: "row" (左右) or "col" (上下)
  local axis = node[1]
  local children = node[2]

  return {
    kind = axis,
    first = convert_node(children[1]),
    second = convert_node(children[2]),
  }
end

--- 現在のレイアウトを取得
--- @return Layout レイアウトツリー
function M.get()
  local window = require("kyoh86.lib.pane_layout.window")
  local layout = window.get_layout()
  return { cur = window.get_path(layout, vim.api.nvim_get_current_win(), ""), root = convert_node(layout) }
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

  M.reset_and_apply(layout)
end

return M
