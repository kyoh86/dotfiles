local M = {}

--- 指定の関数のすべての引数を束縛した関数を返す
--- @param f function
--- @param ... any
--- @return function
--- @usage
--- local f = function(a, b, c) return a + b + c end
--- local g = bind_all(f, 1, 2, 3)
--- print(g()) -- 6
function M.bind_all(f, ...)
  local args = { ... }
  return function()
    return f(unpack(args))
  end
end

--- 指定の関数の先頭のいくつかの引数を束縛した関数を返す
--- @param f function 関数
--- @param ... any 束縛する引数
--- @return function
function M.bind(f, ...)
  local bound = { ... }
  return function(...)
    local args = { ... }
    local merged = {}
    for v in ipairs(bound) do
      table.insert(merged, v)
    end
    for v in ipairs(args) do
      table.insert(merged, v)
    end
    return f(unpack(merged))
  end
end

return M
