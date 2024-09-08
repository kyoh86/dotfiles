local M = {}

--- 指定の関数のすべての引数を束縛した関数を返す。
--- 元の関数の戻り値をそのまま同じく返すので、autocmdのcallbackに使用する場合は
--- truthy returnでautocmdの削除が行われる点に注意すること。
--- ref: `:help nvim_create_autocmd()`
--- 戻り値のvoid化はこのモジュールの`func.void`などを利用できる。
---
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
--- 元の関数の戻り値をそのまま同じく返すので、autocmdのcallbackに使用する場合は
--- truthy returnでautocmdの削除が行われる点に注意すること。
--- ref: `:help nvim_create_autocmd()`
--- 戻り値のvoid化はこのモジュールの`func.void`などを利用できる。
---
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

--- 指定の関数の戻り値をvoidとしつつ、先頭のいくつかの引数を束縛した関数を返す。
--- void(bind(f, ...))の糖衣関数
---
--- @param f function 関数
--- @param ... any 束縛する引数
--- @return function
function M.vind(f, ...)
  return M.void(M.bind(f, ...))
end

--- 指定の関数の戻り値をvoidとしつつ、すべての引数を束縛した関数を返す。
--- void(bind_all(f, ...))の糖衣関数
---
--- @param f function 関数
--- @param ... any 束縛する引数
--- @return function
function M.vind_all(f, ...)
  return M.void(M.bind_all(f, ...))
end

--- 指定の関数の戻り値をvoidとする。
--- 戻り値がある関数を、戻り値に特殊な意味を持たせる文脈で使いたい場合などに使用する。
--- 例: nvim_create_autocmdのcallbackはtruthy returnでautocmdを削除してしまう
---
--- @param f function 関数
--- @return function
function M.void(f)
  return function()
    f()
  end
end

--- pcallでwrapした関数を返す
--- @param f function 関数
--- @param ... any 引数
--- @return function
function M.pcalling(f, ...)
  local args = { ... }
  return function()
    pcall(f, unpack(args))
  end
end

return M
