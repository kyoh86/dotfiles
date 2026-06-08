local libpath = require("kyoh86.lib.pane.path")
local libwindow = require("kyoh86.lib.pane.window")
local tree = require("kyoh86.poc.pane.tree")

---@class kyoh86.poc.pane.ActionsContext
---@field state table
---@field config table
---@field draw fun()
---@field notify fun(msg: string, level?: integer)

local M = {}

---@param ctx kyoh86.poc.pane.ActionsContext
---@return table
function M.new(ctx)
  local state = ctx.state
  local config = ctx.config

  ---@return kyoh86.lib.pane.window.LiveNode
  local function selected_node()
    return tree.node_at(libwindow.get_tree(), state.selected_path)
  end

  local function rebuild_layout(node, cur_path)
    local libpane = require("kyoh86.lib.pane")
    local layout = tree.to_libpane(node)
    local cur = cur_path or {}
    libpane.apply({ root = layout, cur = cur })
  end

  local actions = {}

  function actions.select_parent()
    if #state.selected_path > 0 then
      state.selected_path = libpath.parent(state.selected_path)
    end
    ctx.draw()
  end

  function actions.select_child(index)
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
    ctx.draw()
  end

  function actions.select_sibling()
    if #state.selected_path > 0 then
      state.selected_path = libpath.sibling(state.selected_path)
      local win = tree.first_win(selected_node())
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
      end
    end
    ctx.draw()
  end

  function actions.select_focus()
    state.selected_path = tree.path_of_win(libwindow.get_tree(), vim.api.nvim_get_current_win())
    ctx.draw()
  end

  function actions.flip_selected()
    local n = selected_node()
    if not n or tree.is_leaf(n) then
      ctx.draw()
      return
    end

    local layout = libwindow.get_tree()
    local swapped_node = { kind = n.kind, first = n.second, second = n.first }
    local new_layout = tree.replace_node_at_path(layout, state.selected_path, swapped_node)
    local cur_path = tree.path_of_win(layout, vim.api.nvim_get_current_win())
    rebuild_layout(new_layout, cur_path)

    ctx.draw()
  end

  function actions.rotate_selected()
    local n = selected_node()
    if not n or tree.is_leaf(n) then
      ctx.draw()
      return
    end

    local layout = libwindow.get_tree()
    local new_axis = n.kind == "row" and "col" or "row"
    local rotated_node = {
      kind = new_axis,
      first = n.first,
      second = n.second,
    }
    local new_layout = tree.replace_node_at_path(layout, state.selected_path, rotated_node)
    local cur_path = tree.path_of_win(layout, vim.api.nvim_get_current_win())
    rebuild_layout(new_layout, cur_path)

    state.selected_path = tree.path_of_win(libwindow.get_tree(), vim.api.nvim_get_current_win())
    actions.select_parent()
  end

  function actions.toggle_selected()
    local n = selected_node()
    if not n or tree.is_leaf(n) then
      ctx.draw()
      return
    end

    local layout = libwindow.get_tree()
    local new_axis = n.kind == "row" and "col" or "row"
    local toggled_node = { kind = new_axis, first = n.first, second = n.second }
    local new_layout = tree.replace_node_at_path(layout, state.selected_path, toggled_node)
    local cur_path = tree.path_of_win(layout, vim.api.nvim_get_current_win())
    rebuild_layout(new_layout, cur_path)

    ctx.draw()
  end

  function actions.grow_child(index)
    local layout = libwindow.get_tree()
    local n = tree.node_at(layout, state.selected_path)
    if not n or tree.is_leaf(n) then
      ctx.draw()
      return
    end

    local axis = n.kind
    local amount = config.resize_step
    local total1 = tree.total_size(n.first, axis)
    local total2 = tree.total_size(n.second, axis)

    if total1 == 0 or total2 == 0 then
      return
    end

    local new_total1
    local new_total2
    if index == 1 then
      new_total1 = total1 + amount
      new_total2 = total2 - amount
      if new_total2 < 1 then
        new_total2 = 1
        new_total1 = total1 + total2 - 1
      end
    else
      new_total1 = total1 - amount
      new_total2 = total2 + amount
      if new_total1 < 1 then
        new_total1 = 1
        new_total2 = total1 + total2 - 1
      end
    end

    local resized_node = {
      kind = n.kind,
      first = tree.resize_total(n.first, axis, new_total1),
      second = tree.resize_total(n.second, axis, new_total2),
    }
    local new_layout = tree.replace_node_at_path(layout, state.selected_path, resized_node)
    local cur_path = tree.path_of_win(layout, vim.api.nvim_get_current_win())
    rebuild_layout(new_layout, cur_path)
    ctx.draw()
  end

  function actions.split_selected()
    if not state.preselect then
      ctx.notify("split ignored: press v or s first", vim.log.levels.WARN)
      ctx.draw()
      return
    end

    local node = selected_node()
    if not tree.is_leaf(node) then
      ctx.notify("split ignored: only leaves (panes) can be split", vim.log.levels.WARN)
      ctx.draw()
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
    ctx.draw()
  end

  return actions
end

return M
