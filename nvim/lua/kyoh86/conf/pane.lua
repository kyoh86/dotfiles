-- layout_paredit.nvim prototype
--
-- Usage:
--   Source this file once from your init.lua or plugin loader.
--   <C-w><C-w> enters layout-paredit mode.
--
-- Keys in the mode:
--   h/j/k/l     focus/select neighbor leaf
--   u           select parent subtree
--   1 / 2       select child[1] / child[2]
--   o           select sibling subtree
--   .           select focused leaf
--   H/J/K/L     swap selected subtree with neighbor subtree
--   f           flip selected subtree children
--   r           rotate selected subtree axis
--   [ / ]       grow child[1] / child[2]
--   v           preselect vertical split
--   s           preselect horizontal split
--   <CR>        split selected/focused leaf when preselected
--   <Esc>       cancel preselection, or leave mode when no preselection
--   q / <C-c>   leave mode
--
-- Notes:
--   This is a prototype. Neovim does not expose a direct “set split tree” API.
--   Structural transforms are implemented with existing window commands/functions.
--   Subtree swap/flip mostly swaps window contents for stability.
--   Selection visualization uses floating window frames over the selected subtree.

-- This file intentionally self-registers keymaps/autocmds on load.
-- No setup() call is required.

local state = {
  active = false,
  selected_path = {},
  preselect = nil, -- "v" | "s" | nil
  floats = {},
  keymaps = {},
  drawing = false,
  draw_pending = false,
}

local config = {
  enter_key = "<C-w><C-w>",
  border = "rounded",
  title = " SELECTED ",
  winhighlight = "Normal:LayoutPareditSelection,FloatBorder:LayoutPareditBorder,FloatTitle:LayoutPareditTitle",
  resize_step = 5,
}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "layout-paredit" })
end

local function deepcopy(t)
  if type(t) ~= "table" then
    return t
  end
  local out = {}
  for k, v in pairs(t) do
    out[k] = deepcopy(v)
  end
  return out
end

local function path_parent(path)
  local out = deepcopy(path)
  table.remove(out)
  return out
end

local function path_sibling(path)
  if #path == 0 then
    return path
  end
  local out = deepcopy(path)
  out[#out] = out[#out] == 1 and 2 or 1
  return out
end

local function node_at(layout, path)
  local node = layout
  for _, index in ipairs(path) do
    if node[1] == "leaf" then
      return node
    end
    node = node[2][index]
  end
  return node
end

local function node_type(node)
  return node and node[1]
end

local function is_leaf(node)
  return node_type(node) == "leaf"
end

local function children(node)
  return node[2]
end

local function axis_of(node)
  -- winlayout() returns "row" for side-by-side and "col" for stacked.
  return node[1]
end

local function leaf_winid(node)
  return node[2]
end

local function leaves(node, out)
  out = out or {}
  if is_leaf(node) then
    table.insert(out, leaf_winid(node))
  else
    for _, child in ipairs(children(node)) do
      leaves(child, out)
    end
  end
  return out
end

local function all_nodes(node, path, out)
  path = path or {}
  out = out or {}
  table.insert(out, { node = node, path = deepcopy(path) })
  if not is_leaf(node) then
    for i, child in ipairs(children(node)) do
      local p = deepcopy(path)
      table.insert(p, i)
      all_nodes(child, p, out)
    end
  end
  return out
end

local function compact(node)
  if is_leaf(node) then
    return tostring(leaf_winid(node))
  end
  local op = axis_of(node) == "row" and "|" or "/"
  local parts = {}
  for _, child in ipairs(children(node)) do
    table.insert(parts, compact(child))
  end
  return "(" .. table.concat(parts, op) .. ")"
end

local function first_leaf(node)
  if is_leaf(node) then
    return leaf_winid(node)
  end
  return first_leaf(children(node)[1])
end

local function normalizeToBinary(node)
  if is_leaf(node) then
    return node
  end

  local axis = axis_of(node)
  local childs = children(node)

  -- 子ノードを再帰的に正規化
  local normalizedChildren = {}
  for i, child in ipairs(childs) do
    normalizedChildren[i] = normalizeToBinary(child)
  end

  -- 子が0個または1個の場合
  if #normalizedChildren == 0 then
    return node
  end
  if #normalizedChildren == 1 then
    return normalizedChildren[1]
  end
  if #normalizedChildren == 2 then
    return { axis, normalizedChildren }
  end

  -- Left-associative folding: [A, B, C, D] -> [[[A, B], C], D]
  local result = normalizedChildren[1]
  for i = 2, #normalizedChildren do
    result = { axis, { result, normalizedChildren[i] } }
  end
  return result
end

local function normalized_layout()
  return normalizeToBinary(vim.fn.winlayout())
end

local function path_of_winid(layout, winid)
  for _, item in ipairs(all_nodes(layout)) do
    if is_leaf(item.node) and leaf_winid(item.node) == winid then
      return item.path
    end
  end
  return {}
end

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

local function node_rect(node)
  local rect = nil
  for _, winid in ipairs(leaves(node)) do
    rect = union_rect(rect, win_rect(winid))
  end
  return rect
end

local function center_rect(rect)
  return {
    row = rect.row + rect.height / 2,
    col = rect.col + rect.width / 2,
  }
end

local function selected_node()
  return node_at(normalized_layout(), state.selected_path)
end

local function selected_text()
  local node = selected_node()
  if not node then
    return "<none>"
  end
  return compact(node) .. " path=[" .. table.concat(state.selected_path, ",") .. "]"
end

local function close_floats()
  for _, win in ipairs(state.floats) do
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
  state.floats = {}
end

local function ensure_highlights()
  vim.api.nvim_set_hl(0, "LayoutPareditSelection", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "LayoutPareditBorder", { fg = "#ff8bd1", bg = "NONE" })
  vim.api.nvim_set_hl(0, "LayoutPareditTitle", { fg = "#101217", bg = "#ff8bd1", bold = true })
  vim.api.nvim_set_hl(0, "LayoutPareditPreselectBorder", { fg = "#7ee787", bg = "NONE" })
  vim.api.nvim_set_hl(0, "LayoutPareditPreselectTitle", { fg = "#101217", bg = "#7ee787", bold = true })
end

local function open_line(row, col, width, height, lines, hl, zindex)
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

local function open_frame(rect, title, hl)
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

  open_line(row, col, width, 1, { top_text }, border_hl, 210)
  open_line(bottom, col, width, 1, { bottom_text }, border_hl, 210)

  if height > 2 then
    local side_lines = {}
    for _ = 1, height - 2 do
      table.insert(side_lines, "│")
    end
    open_line(row + 1, col, 1, height - 2, side_lines, border_hl, 210)
    open_line(row + 1, right, 1, height - 2, side_lines, border_hl, 210)
  end
end

local function draw()
  if not state.active or state.drawing then
    return
  end
  state.drawing = true
  ensure_highlights()
  close_floats()

  local layout = normalized_layout()
  local node = node_at(layout, state.selected_path)
  local rect = node_rect(node)
  open_frame(rect, " SELECTED " .. selected_text() .. " ", config.winhighlight)

  if state.preselect then
    local pre_title = state.preselect == "v" and " PRESELECT vertical split " or " PRESELECT horizontal split "
    open_frame(rect, pre_title, "Normal:LayoutPareditSelection,FloatBorder:LayoutPareditPreselectBorder,FloatTitle:LayoutPareditPreselectTitle")

    -- Draw ghost frame for split preview
    local ghost_rect = {}
    if state.preselect == "v" then
      -- Vertical split: new window on the right
      local new_width = math.floor(rect.width / 2)
      ghost_rect = {
        row = rect.row,
        col = rect.col + rect.width - new_width,
        width = new_width,
        height = rect.height,
      }
    else
      -- Horizontal split: new window below
      local new_height = math.floor(rect.height / 2)
      ghost_rect = {
        row = rect.row + rect.height - new_height,
        col = rect.col,
        width = rect.width,
        height = new_height,
      }
    end

    if ghost_rect.width > 1 and ghost_rect.height > 1 then
      open_frame(ghost_rect, " NEW WINDOW ", "Normal:LayoutPareditSelection,FloatBorder:LayoutPareditPreselectBorder,FloatTitle:LayoutPareditPreselectTitle")
    end
  end

  vim.api.nvim_echo({ { "layout-paredit: " .. selected_text() .. (state.preselect and (" preselect=" .. state.preselect .. ", Enter to split") or ""), "ModeMsg" } }, false, {})
  state.drawing = false
end

local function schedule_draw()
  if not state.active or state.draw_pending then
    return
  end
  state.draw_pending = true
  vim.schedule(function()
    state.draw_pending = false
    draw()
  end)
end

local function focus_neighbor(dir)
  local cur = vim.api.nvim_get_current_win()
  local cur_rect = win_rect(cur)
  if not cur_rect then
    return
  end
  local cur_center = center_rect(cur_rect)

  local layout = normalized_layout()
  local candidates = {}

  for _, item in ipairs(all_nodes(layout)) do
    if is_leaf(item.node) then
      local winid = leaf_winid(item.node)
      if winid ~= cur then
        local rect = win_rect(winid)
        if rect then
          local nc = center_rect(rect)
          local dx = nc.col - cur_center.col
          local dy = nc.row - cur_center.row
          local ok = false
          if dir == "h" then
            ok = dx < 0 and math.abs(dy) < rect.height / 2
          elseif dir == "l" then
            ok = dx > 0 and math.abs(dy) < rect.height / 2
          elseif dir == "k" then
            ok = dy < 0 and math.abs(dx) < rect.width / 2
          elseif dir == "j" then
            ok = dy > 0 and math.abs(dx) < rect.width / 2
          end
          if ok then
            local primary = (dir == "h" or dir == "l") and math.abs(dx) or math.abs(dy)
            local secondary = (dir == "h" or dir == "l") and math.abs(dy) or math.abs(dx)
            table.insert(candidates, { winid = winid, score = primary * 10 + secondary })
          end
        end
      end
    end
  end

  if #candidates > 0 then
    table.sort(candidates, function(a, b)
      return a.score < b.score
    end)
    vim.api.nvim_set_current_win(candidates[1].winid)
    state.selected_path = path_of_winid(normalized_layout(), candidates[1].winid)
  end
  draw()
end

local function select_parent()
  if #state.selected_path > 0 then
    state.selected_path = path_parent(state.selected_path)
  end
  draw()
end

local function select_child(index)
  local n = selected_node()
  if n and not is_leaf(n) and children(n)[index] then
    table.insert(state.selected_path, index)
    local winid = first_leaf(node_at(normalized_layout(), state.selected_path))
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_set_current_win(winid)
    end
  end
  draw()
end

local function select_sibling()
  if #state.selected_path > 0 then
    state.selected_path = path_sibling(state.selected_path)
    local winid = first_leaf(selected_node())
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_set_current_win(winid)
    end
  end
  draw()
end

local function select_focus()
  state.selected_path = path_of_winid(normalized_layout(), vim.api.nvim_get_current_win())
  draw()
end

local function sort_wins_by_geometry(wins)
  table.sort(wins, function(a, b)
    local ar = win_rect(a)
    local br = win_rect(b)
    if not ar or not br then
      return a < b
    end
    if math.abs(ar.row - br.row) > 0 then
      return ar.row < br.row
    end
    return ar.col < br.col
  end)
  return wins
end

local function swap_win_contents(a, b)
  if a == b then
    return
  end
  if not vim.api.nvim_win_is_valid(a) or not vim.api.nvim_win_is_valid(b) then
    return
  end

  local abuf = vim.api.nvim_win_get_buf(a)
  local bbuf = vim.api.nvim_win_get_buf(b)
  local acur = vim.api.nvim_win_get_cursor(a)
  local bcur = vim.api.nvim_win_get_cursor(b)
  local atop = vim.fn.getwininfo(a)[1].topline
  local btop = vim.fn.getwininfo(b)[1].topline

  vim.api.nvim_win_set_buf(a, bbuf)
  vim.api.nvim_win_set_buf(b, abuf)

  pcall(vim.api.nvim_win_set_cursor, a, bcur)
  pcall(vim.api.nvim_win_set_cursor, b, acur)
  pcall(vim.fn.win_execute, a, "normal! " .. btop .. "zt")
  pcall(vim.fn.win_execute, b, "normal! " .. atop .. "zt")
end

-- winlayout形式をpane_layout形式に変換する
local function convert_to_pane_layout(node)
  if is_leaf(node) then
    local winid = leaf_winid(node)
    local bufnr = vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) or nil
    return {
      kind = "pane",
      buffer = bufnr,
    }
  end

  local axis = axis_of(node)
  local childs = children(node)

  -- firstノードのサイズを計算
  local first_rect = node_rect(childs[1])
  local second_rect = node_rect(childs[2])
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
    first = convert_to_pane_layout(childs[1]),
    second = convert_to_pane_layout(childs[2]),
    size = size,
  }
end

-- rebuild_layout: 操作後のあるべき姿に基づいてウィンドウを再構築
local function rebuild_layout(node)
  local pane_layout = require("kyoh86.lib.pane_layout")
  local layout = convert_to_pane_layout(node)
  pane_layout.reset_and_apply(layout)
end

-- replace_node_at_path: パスに従ってノードを置換する（winlayout形式）
local function replace_node_at_path(layout, path, new_node)
  if #path == 0 then
    return new_node
  end

  if is_leaf(layout) then
    return layout
  end

  local index = path[1]
  local rest_path = {}
  for i = 2, #path do
    table.insert(rest_path, path[i])
  end

  local axis = axis_of(layout)
  local childs = children(layout)

  local new_childs = {}
  for i, child in ipairs(childs) do
    if i == index then
      table.insert(new_childs, replace_node_at_path(child, rest_path, new_node))
    else
      table.insert(new_childs, child)
    end
  end

  return { axis, new_childs }
end

-- replace_node_at_path_pane_layout: パスに従ってノードを置換する（pane_layout形式）
local function replace_node_at_path_pane_layout(layout, path, new_node)
  if #path == 0 then
    return new_node
  end

  if layout.kind == "pane" then
    return layout
  end

  local index = path[1]
  local rest_path = {}
  for i = 2, #path do
    table.insert(rest_path, path[i])
  end

  local new_layout
  if index == 1 then
    new_layout = {
      kind = layout.kind,
      first = replace_node_at_path_pane_layout(layout.first, rest_path, new_node),
      second = layout.second,
      size = layout.size,
    }
  else
    new_layout = {
      kind = layout.kind,
      first = layout.first,
      second = replace_node_at_path_pane_layout(layout.second, rest_path, new_node),
      size = layout.size,
    }
  end

  return new_layout
end

-- apply_layout: ツリー構造に基づいてウィンドウを再配置
local function apply_layout(node)
  if not node then
    return
  end

  if is_leaf(node) then
    return
  end

  local axis = axis_of(node)
  local childs = children(node)

  -- 各 child を再帰的に配置
  local prev_win = nil
  for i, child in ipairs(childs) do
    -- まず child の内部を配置
    apply_layout(child)

    -- child の最初の leaf を取得
    local first_leaf_ref = first_leaf(child)
    if not vim.api.nvim_win_is_valid(first_leaf_ref) then
      goto continue
    end

    if i == 1 then
      -- 最初の child は何もしない（基準位置）
      prev_win = first_leaf_ref
    else
      -- 2番目以降の child は、前の child の隣に配置
      if prev_win and vim.api.nvim_win_is_valid(prev_win) then
        pcall(vim.fn.win_splitmove, first_leaf_ref, prev_win, { vertical = axis == "col", rightbelow = true })
      end
      prev_win = first_leaf_ref
    end

    ::continue::
  end
end

local function flip_selected()
  local n = selected_node()
  if not n or is_leaf(n) then
    draw()
    return
  end

  -- 全体のレイアウトを取得
  local layout = normalized_layout()

  -- 元の children を保存
  local original_childs = children(n)

  -- children を swap した「新しいノード」を作る
  local axis = axis_of(n)
  local swapped_node = { axis, { original_childs[2], original_childs[1] } }

  -- 全体のレイアウトの該当位置に新しいノードを埋め込む
  local new_layout = replace_node_at_path(layout, state.selected_path, swapped_node)

  -- ウィンドウを再構築
  rebuild_layout(new_layout)

  draw()
end

local function rotate_selected()
  -- Rotate split direction: row <-> col
  local n = selected_node()
  if not n or is_leaf(n) then
    draw()
    return
  end

  -- 全体のレイアウトを取得（pane_layout形式）
  local layout = convert_to_pane_layout(normalized_layout())

  -- 選択されたノードをpane_layout形式で取得
  local pane_n = convert_to_pane_layout(n)

  local axis = axis_of(n)
  local childs = children(n)

  -- axis を反転した新しいノードを作る
  local new_axis = axis == "row" and "col" or "row"

  -- 現在の分割比率を計算して、新しい分割方向に反映
  local first_child_rect = node_rect(childs[1])
  local second_child_rect = node_rect(childs[2])
  local node_rect_n = node_rect(n)
  if not first_child_rect or not second_child_rect or not node_rect_n then
    draw()
    return
  end

  -- 現在の分割サイズを取得
  local current_first_size
  local current_total_size
  if axis == "row" then
    -- row: 幅で分割
    current_first_size = first_child_rect.width
    current_total_size = first_child_rect.width + second_child_rect.width
  else
    -- col: 高さで分割
    current_first_size = first_child_rect.height
    current_total_size = first_child_rect.height + second_child_rect.height
  end

  -- 縦横が同じサイズかどうかをチェック（ノード自体のサイズ）
  local is_square = current_total_size == (axis == "row" and node_rect_n.height or node_rect_n.width)

  -- 新しい分割方向で同じ比率になるようなsizeを計算
  local new_size = nil
  if current_first_size and current_total_size then
    if is_square then
      -- 縦横が同じサイズなら、そのままsizeを流用
      new_size = current_first_size
    else
      -- 縦横が違うサイズなら、「サイズの比率」として反映
      local ratio = current_first_size / current_total_size

      -- デバッグ情報
      notify(string.format("rotate: %s -> %s, first=%d, total=%d, ratio=%.3f",
        axis, new_axis, current_first_size or 0, current_total_size or 0, ratio or 0), vim.log.levels.INFO)

      if ratio then
        if new_axis == "row" then
          -- row: 幅としてsizeを計算
          new_size = math.floor(current_total_size * ratio + 0.5)
        else
          -- col: 高さとしてsizeを計算
          new_size = math.floor(current_total_size * ratio + 0.5)
        end

        notify(string.format("rotate: new_size=%d (from total=%d * ratio=%.3f)",
          new_size or 0, current_total_size or 0, ratio or 0), vim.log.levels.INFO)
      end
    end
  end

  -- 新しいノードを作る（pane_layout形式）
  local rotated_node = {
    kind = new_axis,
    first = convert_to_pane_layout(childs[1]),
    second = convert_to_pane_layout(childs[2]),
    size = new_size,
  }

  -- 全体のレイアウトの該当位置に新しいノードを埋め込む
  local new_layout = replace_node_at_path_pane_layout(layout, state.selected_path, rotated_node)

  -- ウィンドウを再構築
  local pane_layout = require("kyoh86.lib.pane_layout")
  pane_layout.reset_and_apply(new_layout)

  -- 選択パスを更新（ルートから現在のウィンドウへのパスを再取得して親を選択）
  local cur = vim.api.nvim_get_current_win()
  state.selected_path = path_of_winid(normalized_layout(), cur)
  select_parent()
end

local function toggle_selected()
  -- Toggle split direction: H <-> V
  local n = selected_node()
  if not n or is_leaf(n) then
    draw()
    return
  end

  -- 全体のレイアウトを取得
  local layout = normalized_layout()

  local axis = axis_of(n)
  local childs = children(n)

  -- axis を反転した新しいノードを作る
  local new_axis = axis == "row" and "col" or "row"
  local toggled_node = { new_axis, childs }

  -- 全体のレイアウトの該当位置に新しいノードを埋め込む
  local new_layout = replace_node_at_path(layout, state.selected_path, toggled_node)

  -- ウィンドウを再構築
  rebuild_layout(new_layout)

  -- 選択パスを更新（ルートから現在のウィンドウへのパスを再取得）
  local cur = vim.api.nvim_get_current_win()
  state.selected_path = path_of_winid(normalized_layout(), cur)

  draw()
end

local function grow_child(index)
  local n = selected_node()
  if not n or is_leaf(n) then
    draw()
    return
  end

  local axis = axis_of(n)
  local childs = children(n)
  local amount = config.resize_step

  -- 各 children の leaves を取得
  local leaves1 = leaves(childs[1])
  local leaves2 = leaves(childs[2])

  if #leaves1 == 0 or #leaves2 == 0 then
    return
  end

  -- children[1] の各 leaf の現在サイズを取得
  local sizes1 = {}
  local total1 = 0
  for _, win in ipairs(leaves1) do
    if vim.api.nvim_win_is_valid(win) then
      local size = axis == "row" and vim.api.nvim_win_get_width(win) or vim.api.nvim_win_get_height(win)
      table.insert(sizes1, size)
      total1 = total1 + size
    else
      table.insert(sizes1, 0)
    end
  end

  -- children[2] の各 leaf の現在サイズを取得
  local sizes2 = {}
  local total2 = 0
  for _, win in ipairs(leaves2) do
    if vim.api.nvim_win_is_valid(win) then
      local size = axis == "row" and vim.api.nvim_win_get_width(win) or vim.api.nvim_win_get_height(win)
      table.insert(sizes2, size)
      total2 = total2 + size
    else
      table.insert(sizes2, 0)
    end
  end

  if total1 == 0 or total2 == 0 then
    return
  end

  local cur = vim.api.nvim_get_current_win()

  if index == 1 then
    -- children[1] を拡大、children[2] を縮小
    local new_total1 = total1 + amount
    local new_total2 = total2 - amount
    if new_total2 < 1 then
      new_total2 = 1
      new_total1 = total1 + total2 - 1
    end

    -- children[1] をリサイズ
    local target1 = {}
    local t1 = 0
    for i, size in ipairs(sizes1) do
      local target = math.floor(size * new_total1 / total1)
      table.insert(target1, target)
      t1 = t1 + target
    end
    target1[#target1] = target1[#target1] + (new_total1 - t1)

    for i, win in ipairs(leaves1) do
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
        local cmd = (axis == "row") and ("vertical resize " .. target1[i]) or ("resize " .. target1[i])
        vim.cmd(cmd)
      end
    end

    -- children[2] をリサイズ
    local target2 = {}
    local t2 = 0
    for i, size in ipairs(sizes2) do
      local target = math.floor(size * new_total2 / total2)
      table.insert(target2, target)
      t2 = t2 + target
    end
    target2[#target2] = target2[#target2] + (new_total2 - t2)

    for i, win in ipairs(leaves2) do
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
        local cmd = (axis == "row") and ("vertical resize " .. target2[i]) or ("resize " .. target2[i])
        vim.cmd(cmd)
      end
    end
  else
    -- children[1] を縮小、children[2] を拡大
    local new_total1 = total1 - amount
    local new_total2 = total2 + amount
    if new_total1 < 1 then
      new_total1 = 1
      new_total2 = total1 + total2 - 1
    end

    -- children[1] をリサイズ
    local target1 = {}
    local t1 = 0
    for i, size in ipairs(sizes1) do
      local target = math.floor(size * new_total1 / total1)
      table.insert(target1, target)
      t1 = t1 + target
    end
    target1[#target1] = target1[#target1] + (new_total1 - t1)

    for i, win in ipairs(leaves1) do
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
        local cmd = (axis == "row") and ("vertical resize " .. target1[i]) or ("resize " .. target1[i])
        vim.cmd(cmd)
      end
    end

    -- children[2] をリサイズ
    local target2 = {}
    local t2 = 0
    for i, size in ipairs(sizes2) do
      local target = math.floor(size * new_total2 / total2)
      table.insert(target2, target)
      t2 = t2 + target
    end
    target2[#target2] = target2[#target2] + (new_total2 - t2)

    for i, win in ipairs(leaves2) do
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
        local cmd = (axis == "row") and ("vertical resize " .. target2[i]) or ("resize " .. target2[i])
        vim.cmd(cmd)
      end
    end
  end

  if vim.api.nvim_win_is_valid(cur) then
    vim.api.nvim_set_current_win(cur)
  end
  draw()
end

local function split_selected()
  if not state.preselect then
    notify("split ignored: press v or s first", vim.log.levels.WARN)
    draw()
    return
  end

  local node = selected_node()
  if not is_leaf(node) then
    notify("split ignored: only leaves (panes) can be split", vim.log.levels.WARN)
    draw()
    return
  end

  local target = leaf_winid(node)
  if not vim.api.nvim_win_is_valid(target) then
    return
  end

  vim.api.nvim_set_current_win(target)
  if state.preselect == "v" then
    vim.cmd("vnew")
  else
    vim.cmd("new")
  end
  state.preselect = nil
  state.selected_path = path_of_winid(normalized_layout(), vim.api.nvim_get_current_win())
  draw()
end

local function clear_mode_maps()
  for _, map in ipairs(state.keymaps) do
    local opts = {}
    if map.buf and map.buf ~= 0 then
      opts.buffer = map.buf
    end
    pcall(vim.keymap.del, map.mode, map.lhs, opts)
  end
  state.keymaps = {}
end

local function leave()
  state.active = false
  state.preselect = nil
  clear_mode_maps()
  close_floats()
  vim.api.nvim_echo({ { "layout-paredit: leave", "ModeMsg" } }, false, {})
end

local function cancel_or_leave()
  if state.preselect then
    state.preselect = nil
    draw()
  else
    leave()
  end
end

local mode_maps = {
  {
    "h",
    function()
      focus_neighbor("h")
    end,
  },
  {
    "j",
    function()
      focus_neighbor("j")
    end,
  },
  {
    "k",
    function()
      focus_neighbor("k")
    end,
  },
  {
    "l",
    function()
      focus_neighbor("l")
    end,
  },
  { "u", select_parent },
  {
    "1",
    function()
      select_child(1)
    end,
  },
  {
    "2",
    function()
      select_child(2)
    end,
  },
  { "o", select_sibling },
  { ".", select_focus },
  { "f", flip_selected },
  { "r", rotate_selected },
  { "t", toggle_selected },
  {
    "[",
    function()
      grow_child(1)
    end,
  },
  {
    "]",
    function()
      grow_child(2)
    end,
  },
  {
    "v",
    function()
      state.preselect = "v"
      draw()
    end,
  },
  {
    "s",
    function()
      state.preselect = "s"
      draw()
    end,
  },
  { "<CR>", split_selected },
  { "<Esc>", cancel_or_leave },
  { "q", leave },
  { "<C-c>", leave },
}

local function set_mode_maps(buf)
  state.keymaps = {}
  for _, item in ipairs(mode_maps) do
    local lhs = item[1]
    local rhs = item[2]
    local opts = {
      buffer = buf,
      nowait = true,
      silent = true,
      desc = "layout-paredit " .. lhs,
    }
    -- グローバルマッピングの場合は buffer を明示的に指定しない
    if buf == 0 then
      opts.buffer = nil
    end
    local map_id = vim.keymap.set("n", lhs, rhs, opts)
    table.insert(state.keymaps, { mode = "n", lhs = lhs, rhs = rhs, id = map_id, buf = buf })
  end
end

local function enter()
  state.active = true
  state.preselect = nil
  state.selected_path = path_of_winid(normalized_layout(), vim.api.nvim_get_current_win())
  set_mode_maps(0)
  draw()
end

ensure_highlights()

vim.keymap.set("n", config.enter_key, function()
  enter()
end, { desc = "enter layout-paredit mode" })

vim.api.nvim_create_autocmd("WinResized", {
  callback = function()
    schedule_draw()
  end,
})

-- Do not close/reopen floats on ModeChanged; that causes visible flicker when
-- entering the prototype mode and when mappings are executed.
