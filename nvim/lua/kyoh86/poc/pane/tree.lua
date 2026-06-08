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
