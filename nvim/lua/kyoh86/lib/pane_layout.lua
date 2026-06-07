-- pane_layout.lua
-- ペインレイアウトをツリー構造から構築するライブラリ

local M = {}

-- レイアウトツリーの構造:
-- {
--   kind = "pane",      -- リーフ（ペイン）
--   buffer = number,    -- bufnr (省略時は空バッファ)
-- }
-- または
-- {
--   kind = "row" | "col",  -- 分割方向 (row=左右, col=上下)
--   first = Node,       -- 左/上の子
--   second = Node,      -- 右/下の子
--   size = number,      -- firstのサイズ（列数または行数、省略時は均等分割）
-- }

-- ノードを構築する
-- 戻り値: {node, win} のペア
function M.build_node(node, parent_win)
  if node.kind == "pane" then
    -- 葉: parent_win にバッファを設定
    if node.buffer then
      vim.api.nvim_win_set_buf(parent_win, node.buffer)
    end
    return { node = node, win = parent_win }
  end

  -- row/col: parent_win を分割して first_win と second_win を作成
  vim.api.nvim_set_current_win(parent_win)
  if node.kind == "col" then
    vim.cmd("belowright split")
  else
    vim.cmd("belowright vsplit")
  end
  local second_win = vim.api.nvim_get_current_win()
  local first_win = parent_win

  -- サイズを固定するオプションを設定（子ノード構築前にサイズを固定）
  local wo = vim.api.nvim_get_option_value("winfixheight", { win = first_win })
  local wo_v = vim.api.nvim_get_option_value("winfixwidth", { win = first_win })
  if node.kind == "col" then
    vim.api.nvim_set_option_value("winfixheight", true, { win = first_win })
  else
    vim.api.nvim_set_option_value("winfixwidth", true, { win = first_win })
  end

  -- 子ノード構築前にサイズを設定
  if node.size then
    vim.api.nvim_set_current_win(first_win)
    if node.kind == "col" then
      vim.cmd("resize " .. node.size)
    else
      vim.cmd("vertical resize " .. node.size)
    end
  end

  -- first を構築
  local first_result = M.build_node(node.first, first_win)

  -- second を構築
  local second_result = M.build_node(node.second, second_win)

  -- 子ノード構築後にサイズを再設定（内側の構築によってサイズが変更された場合に修正）
  if node.size then
    vim.api.nvim_set_current_win(first_win)
    if node.kind == "col" then
      vim.cmd("resize " .. node.size)
    else
      vim.cmd("vertical resize " .. node.size)
    end
  end

  -- サイズ固定オプションを元に戻す
  vim.api.nvim_set_option_value("winfixheight", wo, { win = first_win })
  vim.api.nvim_set_option_value("winfixwidth", wo_v, { win = first_win })

  return { node = node, win = first_win, first = first_result, second = second_result }
end

-- トップダウンでサイズを適用（ルート→葉）
local function apply_sizes_topdown(node_win_pair)
  if not node_win_pair or not node_win_pair.node then
    return
  end

  local node = node_win_pair.node

  if node.kind == "pane" then
    return
  end

  -- 自分のサイズを先に適用
  if node.size then
    local win = node_win_pair.win
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
      if node.kind == "col" then
        vim.cmd("resize " .. node.size)
      else
        vim.cmd("vertical resize " .. node.size)
      end
    end
  end

  -- 子ノードのサイズを後に適用（トップダウン）
  if node_win_pair.first then
    apply_sizes_topdown(node_win_pair.first)
  end
  if node_win_pair.second then
    apply_sizes_topdown(node_win_pair.second)
  end
end

-- レイアウトを適用
-- layout: レイアウトツリー
-- parent_win: 親ウィンドウ（通常は省略）
function M.apply(layout, parent_win)
  parent_win = parent_win or vim.api.nvim_get_current_win()
  M.build_node(layout, parent_win)
end

-- すべてのウィンドウを閉じて、レイアウトを適用
-- layout: レイアウトツリー
function M.reset_and_apply(layout)
  -- 最初のウィンドウ以外を閉じる
  local first_win = vim.api.nvim_list_wins()[1]
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= first_win then
      vim.api.nvim_win_close(win, true)
    end
  end

  -- レイアウトを適用
  M.apply(layout, first_win)
end

-- vim.fn.winlayout() の結果をバイナリツリーに正規化
local function normalize_to_binary(node)
  if node[1] == "leaf" then
    return node
  end

  local axis = node[1]  -- "row" or "col"
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
      normalize_to_binary(children[2])
    }}
  end

  -- 3つ以上の場合は左結合で畳み込む
  local result = normalize_to_binary(children[1])
  for i = 2, #children do
    result = { axis, { result, normalize_to_binary(children[i]) } }
  end
  return result
end

-- ノードのすべての葉（ウィンドウID）を収集
local function collect_layout_leaves(node)
  if node[1] == "leaf" then
    return { node[2] }
  end

  local result = {}
  for _, child in ipairs(node[2]) do
    for _, leaf in ipairs(collect_layout_leaves(child)) do
      table.insert(result, leaf)
    end
  end
  return result
end

-- ウィンドウの矩形情報を取得
local function win_rect(winid)
  if not vim.api.nvim_win_is_valid(winid) then
    return nil
  end
  local pos = vim.api.nvim_win_get_position(winid)
  local width = vim.api.nvim_win_get_width(winid)
  local height = vim.api.nvim_win_get_height(winid)
  return {
    row = pos[1],
    col = pos[2],
    width = width,
    height = height,
  }
end

-- 矩形の結合（包含する最小の矩形）
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

-- ノードが占める矩形を計算
local function node_rect(node)
  local rect = nil
  for _, winid in ipairs(collect_layout_leaves(node)) do
    rect = union_rect(rect, win_rect(winid))
  end
  return rect
end

-- Neovimのwinlayout形式をユーザー形式に変換
local function convert_node(node)
  if node[1] == "leaf" then
    local winid = node[2]
    local bufnr = vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) or nil
    return {
      kind = "pane",
      buffer = bufnr,
    }
  end

  -- axis: "row" (左右) or "col" (上下)
  local axis = node[1]
  local children = node[2]

  -- firstノードのサイズを計算
  local first_rect = node_rect(children[1])
  local second_rect = node_rect(children[2])
  local size = nil
  if first_rect and second_rect then
    if axis == "row" then
      size = first_rect.width
    else
      size = first_rect.height
    end
  end

  return {
    kind = axis,
    first = convert_node(children[1]),
    second = convert_node(children[2]),
    size = size,
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
