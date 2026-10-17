local M = {}

function M.start_tmux(target)
  -- Compatibility for shells that already loaded the previous ZLE widget.
  require("kyoh86.lib.pick.tools").start_tmux(target)
end

return M
