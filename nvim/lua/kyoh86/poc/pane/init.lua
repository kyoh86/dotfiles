local libpath = require("kyoh86.lib.pane.path")
local libwindow = require("kyoh86.lib.pane.window")
local tree = require("kyoh86.poc.pane.tree")
local view = require("kyoh86.poc.pane.view")
-- layout_paredit.nvim prototype
--
-- Usage:
--   nvim/lua/kyoh86/conf/poc_pane.lua calls setup().
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

-- Call setup() from a conf module to register keymaps/autocmds.

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

---@return kyoh86.lib.pane.window.LiveNode
local function selected_node()
  return tree.node_at(libwindow.get_tree(), state.selected_path)
end

---@return string
local function selected_text()
  local node = selected_node()
  if not node then
    return "<none>"
  end
  return tree.compact(node) .. " path=[" .. table.concat(state.selected_path, ",") .. "]"
end

local function draw()
  if not state.active or state.drawing then
    return
  end
  state.drawing = true
  view.ensure_highlights()
  view.close_floats(state)

  local layout = libwindow.get_tree()
  local node = tree.node_at(layout, state.selected_path)
  local rect = view.node_rect(node)
  view.open_frame(state, config, rect, " SELECTED " .. selected_text() .. " ", config.winhighlight)

  if state.preselect then
    local pre_title = state.preselect == "v" and " PRESELECT vertical split " or " PRESELECT horizontal split "
    view.open_frame(state, config, rect, pre_title, "Normal:LayoutPareditSelection,FloatBorder:LayoutPareditPreselectBorder,FloatTitle:LayoutPareditPreselectTitle")

    -- Draw ghost frame for split preview
    local ghost_rect = {}
    if rect then
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
    end

    if ghost_rect.width and ghost_rect.width > 1 and ghost_rect.height > 1 then
      view.open_frame(state, config, ghost_rect, " NEW WINDOW ", "Normal:LayoutPareditSelection,FloatBorder:LayoutPareditPreselectBorder,FloatTitle:LayoutPareditPreselectTitle")
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

local function select_parent()
  if #state.selected_path > 0 then
    state.selected_path = libpath.parent(state.selected_path)
  end
  draw()
end

local function select_child(index)
  local n = selected_node()
  if n and not tree.is_leaf(n) then
    local child
    if index == 1 then
      child = n.first
    elseif index == 2 then
      child = n.second
    end
    if child then
      table.insert(state.selected_path, index)
      local win = tree.first_win(tree.node_at(libwindow.get_tree(), state.selected_path))
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
      end
    end
  end
  draw()
end

local function select_sibling()
  if #state.selected_path > 0 then
    state.selected_path = libpath.sibling(state.selected_path)
    local win = tree.first_win(selected_node())
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
    end
  end
  draw()
end

local function select_focus()
  state.selected_path = tree.path_of_win(libwindow.get_tree(), vim.api.nvim_get_current_win())
  draw()
end

-- rebuild_layout: 操作後のあるべき姿に基づいてウィンドウを再構築
local function rebuild_layout(node, cur_path)
  local libpane = require("kyoh86.lib.pane")
  local layout = tree.to_libpane(node)
  local cur = cur_path or {}
  libpane.apply({ root = layout, cur = cur })
end

local function flip_selected()
  local n = selected_node()
  if not n or tree.is_leaf(n) then
    draw()
    return
  end

  -- 全体のレイアウトを取得
  local layout = libwindow.get_tree()

  -- children を swap した「新しいノード」を作る
  local axis = n.kind
  local swapped_node = { kind = axis, first = n.second, second = n.first }

  -- 全体のレイアウトの該当位置に新しいノードを埋め込む
  local new_layout = tree.replace_node_at_path(layout, state.selected_path, swapped_node)

  -- 現在のウィンドウのパスを取得
  local cur_win = vim.api.nvim_get_current_win()
  local cur_path = tree.path_of_win(layout, cur_win)

  -- ウィンドウを再構築（フォーカスを復元）
  rebuild_layout(new_layout, cur_path)

  draw()
end

local function rotate_selected()
  -- Rotate split direction: row <-> col
  local n = selected_node()
  if not n or tree.is_leaf(n) then
    draw()
    return
  end

  -- 全体のレイアウトを取得
  local layout = libwindow.get_tree()

  local axis = n.kind

  -- axis を反転した新しいノードを作る
  local new_axis = axis == "row" and "col" or "row"

  local rotated_node = {
    kind = new_axis,
    first = n.first,
    second = n.second,
  }

  -- 全体のレイアウトの該当位置に新しいノードを埋め込む
  local new_layout = tree.replace_node_at_path(layout, state.selected_path, rotated_node)

  -- 現在のウィンドウのパスを取得
  local cur_win = vim.api.nvim_get_current_win()
  local cur_path = tree.path_of_win(layout, cur_win)

  -- ウィンドウを再構築（フォーカスを復元）
  rebuild_layout(new_layout, cur_path)

  -- 選択パスを更新
  state.selected_path = tree.path_of_win(libwindow.get_tree(), vim.api.nvim_get_current_win())
  select_parent()
end

local function toggle_selected()
  -- Toggle split direction: H <-> V
  local n = selected_node()
  if not n or tree.is_leaf(n) then
    draw()
    return
  end

  -- 全体のレイアウトを取得
  local layout = libwindow.get_tree()

  local axis = n.kind
  -- axis を反転した新しいノードを作る
  local new_axis = axis == "row" and "col" or "row"
  local toggled_node = { kind = new_axis, first = n.first, second = n.second }

  -- 全体のレイアウトの該当位置に新しいノードを埋め込む
  local new_layout = tree.replace_node_at_path(layout, state.selected_path, toggled_node)

  -- 現在のウィンドウのパスを取得
  local cur_win = vim.api.nvim_get_current_win()
  local cur_path = tree.path_of_win(layout, cur_win)

  -- ウィンドウを再構築（フォーカスを復元）
  rebuild_layout(new_layout, cur_path)

  draw()
end

local function grow_child(index)
  local n = selected_node()
  if not n or tree.is_leaf(n) then
    draw()
    return
  end

  local axis = n.kind
  local amount = config.resize_step

  -- 各 children の leaves を取得
  local leaves1 = tree.leaves(n.first)
  local leaves2 = tree.leaves(n.second)

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
    for _, size in ipairs(sizes1) do
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
    for _, size in ipairs(sizes2) do
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
    for _, size in ipairs(sizes1) do
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
    for _, size in ipairs(sizes2) do
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
  if not tree.is_leaf(node) then
    notify("split ignored: only leaves (panes) can be split", vim.log.levels.WARN)
    draw()
    return
  end

  local target = node.win
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
  state.selected_path = tree.path_of_win(libwindow.get_tree(), vim.api.nvim_get_current_win())
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
  view.close_floats(state)
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
  state.selected_path = tree.path_of_win(libwindow.get_tree(), vim.api.nvim_get_current_win())
  set_mode_maps(0)
  draw()
end

local M = {}

function M.setup()
  view.ensure_highlights()

  vim.keymap.set("n", config.enter_key, function()
    enter()
  end, { desc = "enter layout-paredit mode" })

  local group = vim.api.nvim_create_augroup("kyoh86-poc-pane", { clear = true })
  vim.api.nvim_create_autocmd("WinResized", {
    group = group,
    callback = function()
      schedule_draw()
    end,
  })
end

return M
