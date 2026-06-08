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

---@class Panes
---@field node Node
---@field win number
---@field first? Panes
---@field second? Panes

---ウィンドウ構造を構築する（サイズ設定はしない）
---@param node Node
---@param win number
---@return Panes
local function build_panes(node, win)
  if node.kind == "pane" then
    -- 葉: parent_win にバッファを設定
    if node.buffer then
      vim.api.nvim_win_set_buf(win, node.buffer)
    end
    return { node = node, win = win }
  else
    vim.api.nvim_set_current_win(win)
    if node.kind == "col" then
      vim.cmd("belowright split")
    else
      vim.cmd("belowright vsplit")
    end
    local new_win = vim.api.nvim_get_current_win()

    -- first を構築
    local first_result = build_panes(node.first, win)

    -- second を構築
    local second_result = build_panes(node.second, new_win)

    return { node = node, win = win, first = first_result, second = second_result }
  end
end

---すべてのペインのサイズを再帰的に設定
---@param panes Panes
local function apply_resize_only(panes)
  if not panes or not panes.node then
    return
  end

  if panes.node.kind == "pane" then
    -- ペインのサイズを設定
    vim.api.nvim_set_current_win(panes.win)
    vim.cmd("resize " .. panes.node.height)
    vim.cmd("vertical resize " .. panes.node.width)
  else
    -- row/colノード: 子を処理
    if panes.first then
      apply_resize_only(panes.first)
    end
    if panes.second then
      apply_resize_only(panes.second)
    end
  end
end

-- レイアウトを適用
-- layout: レイアウトツリー
-- parent_win: 親ウィンドウ（通常は省略）
function M.apply(layout)
  local win = vim.api.nvim_get_current_win()
  local panes = build_panes(layout, win)
  apply_resize_only(panes)
end

-- すべてのウィンドウを閉じて、レイアウトを適用
-- layout: レイアウトツリー
function M.reset_and_apply(layout)
  vim.cmd("only") -- リセット
  M.apply(layout) -- レイアウトを適用
end

-- vim.fn.winlayout() の結果をバイナリツリーに正規化
local function normalize_to_binary(node)
  if node[1] == "leaf" then
    return node
  end

  local axis = node[1] -- "row" or "col"
  local children = node[2]

  if #children == 0 then
    return node
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
    result = { axis, { result, normalize_to_binary(children[i]) } }
  end
  return result
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

-- 現在のレイアウトを取得
-- 戻り値: レイアウトツリー
function M.get()
  local layout = vim.fn.winlayout()
  local normalized = normalize_to_binary(layout)
  return convert_node(normalized)
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
