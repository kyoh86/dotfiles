--- Gets or sets environment variables through parent tmux session.
--- in the current editor process. See |expand-env| and
--- |:let-environment| for the Vimscript behavior. Invalid or unset key returns `nil`.
---
--- Example:
---
--- ```lua
--- envar.FOO = 'bar'
--- print(envar.TERM)
--- ```
return setmetatable({}, {
  __index = function(_, k)
    local v = vim.fn.getenv(k)
    if v == vim.NIL then
      return nil
    end
    return v
  end,

  __newindex = function(_, k, v)
    vim.fn.setenv(k, v)
    vim.system({ "tmux", "set-environment", k, v })
  end,
})

