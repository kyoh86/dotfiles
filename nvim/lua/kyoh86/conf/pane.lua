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

local function path_eq(a, b)
  if #a ~= #b then
    return false
  end
  for i = 1, #a do
    if a[i] ~= b[i] then
      return false
    end
  end
  return true
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

local function is_prefix(a, b)
  if #a > #b then
    return false
  end
  for i = 1, #a do
    if a[i] ~= b[i] then
      return false
    end
  end
  return true
end

local function selected_node()
  return node_at(vim.fn.winlayout(), state.selected_path)
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

  local layout = vim.fn.winlayout()
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

local function neighbor_node(dir)
  local layout = vim.fn.winlayout()
  local selected = node_at(layout, state.selected_path)
  local selected_rect = node_rect(selected)
  if not selected_rect then
    return nil
  end
  local c = center_rect(selected_rect)

  local candidates = {}
  for _, item in ipairs(all_nodes(layout)) do
    if not path_eq(item.path, state.selected_path) and not is_prefix(item.path, state.selected_path) and not is_prefix(state.selected_path, item.path) then
      local r = node_rect(item.node)
      if r then
        local nc = center_rect(r)
        local dx = nc.col - c.col
        local dy = nc.row - c.row
        local ok = false
        if dir == "h" then
          ok = dx < 0
        end
        if dir == "l" then
          ok = dx > 0
        end
        if dir == "k" then
          ok = dy < 0
        end
        if dir == "j" then
          ok = dy > 0
        end
        if ok then
          local primary = (dir == "h" or dir == "l") and math.abs(dx) or math.abs(dy)
          local secondary = (dir == "h" or dir == "l") and math.abs(dy) or math.abs(dx)
          table.insert(candidates, { item = item, score = primary * 10 + secondary })
        end
      end
    end
  end

  table.sort(candidates, function(a, b)
    return a.score < b.score
  end)
  return candidates[1] and candidates[1].item or nil
end

local function focus_neighbor(dir)
  local cur = vim.api.nvim_get_current_win()
  local cur_rect = win_rect(cur)
  if not cur_rect then
    return
  end
  local cur_center = center_rect(cur_rect)

  local layout = vim.fn.winlayout()
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
    state.selected_path = path_of_winid(vim.fn.winlayout(), candidates[1].winid)
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
    local winid = first_leaf(node_at(vim.fn.winlayout(), state.selected_path))
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
  state.selected_path = path_of_winid(vim.fn.winlayout(), vim.api.nvim_get_current_win())
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

local function swap_selected_dir(dir)
  local layout = vim.fn.winlayout()
  local a_node = node_at(layout, state.selected_path)
  local b_item = neighbor_node(dir)
  if not b_item then
    draw()
    return
  end

  local a_wins = sort_wins_by_geometry(leaves(a_node))
  local b_wins = sort_wins_by_geometry(leaves(b_item.node))
  local count = math.min(#a_wins, #b_wins)
  for i = 1, count do
    swap_win_contents(a_wins[i], b_wins[i])
  end

  state.selected_path = b_item.path
  local winid = first_leaf(node_at(vim.fn.winlayout(), state.selected_path))
  if vim.api.nvim_win_is_valid(winid) then
    vim.api.nvim_set_current_win(winid)
  end
  draw()
end

local function flip_selected()
  local n = selected_node()
  if not n or is_leaf(n) then
    draw()
    return
  end
  local a = sort_wins_by_geometry(leaves(children(n)[1]))
  local b = sort_wins_by_geometry(leaves(children(n)[2]))
  local count = math.min(#a, #b)
  for i = 1, count do
    swap_win_contents(a[i], b[i])
  end
  draw()
end

local function rotate_selected()
  -- Best-effort structural rotate for simple selected split:
  -- move child[2]'s first leaf around child[1]'s first leaf with the opposite split direction.
  -- For complex subtrees, this is intentionally conservative.
  local n = selected_node()
  if not n or is_leaf(n) then
    draw()
    return
  end

  local a = first_leaf(children(n)[1])
  local b = first_leaf(children(n)[2])
  if not (vim.api.nvim_win_is_valid(a) and vim.api.nvim_win_is_valid(b)) then
    draw()
    return
  end

  local axis = axis_of(n)
  local ok = pcall(function()
    -- win_splitmove moves source window next to target.
    -- If current node is side-by-side, create a stacked relation; if stacked, create side-by-side.
    vim.fn.win_splitmove(b, a, { vertical = axis == "col", rightbelow = true })
  end)
  if not ok then
    notify("rotate failed for this layout", vim.log.levels.WARN)
  end
  state.selected_path = path_of_winid(vim.fn.winlayout(), a)
  select_parent()
end

local function grow_child(index)
  local n = selected_node()
  if not n or is_leaf(n) then
    draw()
    return
  end

  local axis = axis_of(n)
  local target = first_leaf(children(n)[index])
  if not vim.api.nvim_win_is_valid(target) then
    return
  end

  local cur = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(target)
  local amount = config.resize_step
  if axis == "row" then
    if index == 1 then
      vim.cmd("vertical resize +" .. amount)
    else
      vim.cmd("vertical resize +" .. amount)
    end
  else
    if index == 1 then
      vim.cmd("resize +" .. amount)
    else
      vim.cmd("resize +" .. amount)
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
  local target = first_leaf(node)
  if not vim.api.nvim_win_is_valid(target) then
    return
  end

  local cur = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(target)
  if state.preselect == "v" then
    vim.cmd("vsplit")
  else
    vim.cmd("split")
  end
  state.preselect = nil
  state.selected_path = path_of_winid(vim.fn.winlayout(), vim.api.nvim_get_current_win())
  if vim.api.nvim_win_is_valid(cur) then
    -- Keep the newly created window focused, matching the HTML/tmux prototype.
  end
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
  {
    "H",
    function()
      swap_selected_dir("h")
    end,
  },
  {
    "J",
    function()
      swap_selected_dir("j")
    end,
  },
  {
    "K",
    function()
      swap_selected_dir("k")
    end,
  },
  {
    "L",
    function()
      swap_selected_dir("l")
    end,
  },
  { "f", flip_selected },
  { "r", rotate_selected },
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
  state.selected_path = path_of_winid(vim.fn.winlayout(), vim.api.nvim_get_current_win())
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
