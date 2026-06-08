local M = {}

---@param node kyoh86.lib.pane.window.LiveNode
---@return boolean
function M.is_leaf(node)
  return node and node.kind == "pane"
end

---@param node kyoh86.lib.pane.window.LiveNode
---@return integer[] wins
function M.leaves(node)
  if M.is_leaf(node) then
    return { node.win }
  end
  local list = M.leaves(node.first)
  for _, leaf in ipairs(M.leaves(node.second)) do
    table.insert(list, leaf)
  end
  return list
end

---@param node kyoh86.lib.pane.window.LiveNode
---@param path? kyoh86.lib.pane.Path
---@return {node: kyoh86.lib.pane.window.LiveNode, path: kyoh86.lib.pane.Path }[]
function M.all_nodes(node, path)
  path = path or {}
  local out = { { node = node, path = vim.deepcopy(path) } }
  if M.is_leaf(node) then
    return out
  end
  for i, child in ipairs({ node.first, node.second }) do
    local p = vim.deepcopy(path)
    table.insert(p, i)
    for _, desc in ipairs(M.all_nodes(child, p)) do
      table.insert(out, desc)
    end
  end
  return out
end

---@param node kyoh86.lib.pane.window.LiveNode
---@return integer win
function M.first_win(node)
  if M.is_leaf(node) then
    return node.win
  end
  return M.first_win(node.first)
end

---@param node kyoh86.lib.pane.window.LiveNode
---@param win integer
---@return kyoh86.lib.pane.Path path
function M.path_of_win(node, win)
  for _, item in ipairs(M.all_nodes(node)) do
    if M.is_leaf(item.node) and item.node.win == win then
      return item.path
    end
  end
  return {}
end

---@param root kyoh86.lib.pane.window.LiveNode
---@param path kyoh86.lib.pane.Path
---@return kyoh86.lib.pane.window.LiveNode
function M.node_at(root, path)
  local node = root
  for _, index in ipairs(path) do
    if node.kind == "pane" then
      return node
    end
    node = index == 1 and node.first or node.second
  end
  return node
end

---@param node kyoh86.lib.pane.window.LiveNode
---@return string
function M.compact(node)
  if M.is_leaf(node) then
    return tostring(node.win)
  end
  local op = node.kind == "row" and "|" or "/"
  return "(" .. table.concat({
    M.compact(node.first),
    M.compact(node.second),
  }, op) .. ")"
end

---@param node kyoh86.lib.pane.window.LiveNode
---@return kyoh86.lib.pane.Node
function M.to_libpane(node)
  if M.is_leaf(node) then
    return {
      kind = "pane",
      buffer = node.buffer,
      width = node.width,
      height = node.height,
    }
  end

  return {
    kind = node.kind,
    first = M.to_libpane(node.first),
    second = M.to_libpane(node.second),
  }
end

---@param node kyoh86.lib.pane.window.LiveNode
---@param axis "row"|"col"
---@return integer
function M.total_size(node, axis)
  local total = 0
  for _, item in ipairs(M.all_nodes(node)) do
    if M.is_leaf(item.node) then
      local size = axis == "row" and item.node.width or item.node.height
      total = total + (size or 0)
    end
  end
  return total
end

---@param node kyoh86.lib.pane.window.LiveNode
---@param axis "row"|"col"
---@param targets integer[]
---@param index { value: integer }
---@return kyoh86.lib.pane.window.LiveNode
local function apply_leaf_sizes(node, axis, targets, index)
  if M.is_leaf(node) then
    local size = targets[index.value] or 1
    index.value = index.value + 1
    return {
      kind = "pane",
      win = node.win,
      buffer = node.buffer,
      width = axis == "row" and size or node.width,
      height = axis == "col" and size or node.height,
    }
  end
  return {
    kind = node.kind,
    first = apply_leaf_sizes(node.first, axis, targets, index),
    second = apply_leaf_sizes(node.second, axis, targets, index),
  }
end

---@param node kyoh86.lib.pane.window.LiveNode
---@param axis "row"|"col"
---@param total integer
---@return kyoh86.lib.pane.window.LiveNode
function M.resize_total(node, axis, total)
  local leaves = {}
  local current_total = 0
  for _, item in ipairs(M.all_nodes(node)) do
    if M.is_leaf(item.node) then
      local size = axis == "row" and item.node.width or item.node.height
      size = size or 0
      table.insert(leaves, size)
      current_total = current_total + size
    end
  end
  if #leaves == 0 or current_total == 0 then
    return node
  end

  local targets = {}
  local assigned = 0
  for _, size in ipairs(leaves) do
    local target = math.floor(size * total / current_total)
    table.insert(targets, target)
    assigned = assigned + target
  end
  targets[#targets] = targets[#targets] + (total - assigned)

  return apply_leaf_sizes(node, axis, targets, { value = 1 })
end

---@param layout kyoh86.lib.pane.window.LiveNode
---@param path kyoh86.lib.pane.Path
---@param new_node kyoh86.lib.pane.window.LiveNode
---@return kyoh86.lib.pane.window.LiveNode
function M.replace_node_at_path(layout, path, new_node)
  if #path == 0 then
    return new_node
  end
  if M.is_leaf(layout) then
    return layout
  end

  local index = path[1]
  local rest_path = {}
  for i = 2, #path do
    table.insert(rest_path, path[i])
  end

  if index == 1 then
    return {
      kind = layout.kind,
      first = M.replace_node_at_path(layout.first, rest_path, new_node),
      second = layout.second,
    }
  end
  return {
    kind = layout.kind,
    first = layout.first,
    second = M.replace_node_at_path(layout.second, rest_path, new_node),
  }
end

return M
