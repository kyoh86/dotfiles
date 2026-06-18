local M = {}

-- GitHub PRの作成
function M.create_command(opts)
  local args = opts.args or {}
  local exec = #args == 1 and { "gh", "pr", "new", "--title", args[1] } or { "gh", "pr", "new" }
  require("kyoh86.lib.tmux").run(exec, { quit = "wait" })
end

return M
