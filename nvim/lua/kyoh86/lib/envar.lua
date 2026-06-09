--- Gets or sets environment variables.
--- in the current editor process. See |expand-env| and
--- |:let-environment| for the Vimscript behavior. Invalid or unset key returns `nil`.
---
--- Example:
---
--- ```lua
--- envar.FOO = 'bar'
--- print(envar.TERM)
--- ```
local M = {}

function M.set_tmux(k, v)
  vim.fn.setenv(k, v)
  if vim.env.TMUX then
    vim.system({ "tmux", "set-environment", k, v })
  end
end

return setmetatable(M, {
  __index = function(_, k)
    local method = rawget(M, k)
    if method ~= nil then
      return method
    end
    local v = vim.fn.getenv(k)
    if v == vim.NIL then
      return nil
    end
    return v
  end,

  __newindex = function(_, k, v)
    vim.fn.setenv(k, v)
  end,
})
