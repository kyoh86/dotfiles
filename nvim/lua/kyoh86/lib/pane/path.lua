---@alias kyoh86.lib.pane.PathSegment 1|2
---@alias kyoh86.lib.pane.Path kyoh86.lib.pane.PathSegment[]

local M = {}

---@param path kyoh86.lib.pane.Path
---@return string
function M.to_string(path)
  return "/" .. table.concat(path, "/")
end

---@param path string
---@return kyoh86.lib.pane.Path
function M.from_string(path)
  return vim.split(path, "/", { trimempty = true })
end

---@param path kyoh86.lib.pane.Path|string
---@return boolean
function M.is_root(path)
  return not path or #path == 0 or path == "" or path == "/"
end

---@param path kyoh86.lib.pane.Path
---@return kyoh86.lib.pane.Path
function M.parent(path)
  if #path == 0 then
    return path
  end
  local parent = vim.deepcopy(path)
  table.remove(parent)
  return parent
end

---@param path kyoh86.lib.pane.Path
---@param next kyoh86.lib.pane.PathSegment
---@return kyoh86.lib.pane.Path
function M.child(path, next)
  local child = vim.deepcopy(path)
  table.insert(child, next)
  return child
end

---@param path kyoh86.lib.pane.Path
---@return kyoh86.lib.pane.PathSegment|nil, kyoh86.lib.pane.Path
function M.digg(path)
  if #path == 0 then
    return nil, {}
  end
  local digg = vim.deepcopy(path)
  table.remove(digg, 1)
  return path[1], digg
end

---@param path kyoh86.lib.pane.Path
---@return kyoh86.lib.pane.Path
function M.sibling(path)
  if #path == 0 then
    return path
  end
  local sibling = vim.deepcopy(path)
  sibling[#sibling] = sibling[#sibling] == 1 and 2 or 1
  return sibling
end

return M
