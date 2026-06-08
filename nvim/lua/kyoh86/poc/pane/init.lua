local Actions = require("kyoh86.poc.pane.actions")
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
--   v           split selected/focused leaf vertically
--   s           split selected/focused leaf horizontally
--   <Esc>       leave mode
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

  vim.api.nvim_echo({ { "layout-paredit: " .. selected_text(), "ModeMsg" } }, false, {})
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

local actions = Actions.new({
  state = state,
  config = config,
  draw = draw,
  notify = notify,
})

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
  clear_mode_maps()
  view.close_floats(state)
  vim.api.nvim_echo({ { "layout-paredit: leave", "ModeMsg" } }, false, {})
end

local mode_maps = {
  { "u", actions.select_parent },
  {
    "1",
    function()
      actions.select_child(1)
    end,
  },
  {
    "2",
    function()
      actions.select_child(2)
    end,
  },
  { "o", actions.select_sibling },
  { ".", actions.select_focus },
  { "f", actions.flip_selected },
  { "r", actions.rotate_selected },
  { "t", actions.toggle_selected },
  {
    "[",
    function()
      actions.grow_child(1)
    end,
  },
  {
    "]",
    function()
      actions.grow_child(2)
    end,
  },
  {
    "v",
    function()
      actions.split_selected("v")
    end,
  },
  {
    "s",
    function()
      actions.split_selected("s")
    end,
  },
  { "<Esc>", leave },
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
