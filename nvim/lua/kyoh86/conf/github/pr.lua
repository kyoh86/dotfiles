local M = {}

-- GitHub PRの作成
function M.create_command(opts)
  local args = opts.args or {}
  local exec = "gh pr new"
  if #args == 1 then
    exec = "gh pr new --title " .. args[1]
  end
  require("kyoh86.lib.volatile_terminal").split(0, {}, { exec = exec })
end

return M
