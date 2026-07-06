local M = {}

function M.start_tmux(target)
  require("kyoh86.lib.tmux").focus_nvim_pane()
  vim.fn["ddu#start"]({
    name = "zsh_history_tmux",
    actionParams = {
      ["custom:tmux-paste"] = {
        target = target,
      },
    },
  })
end

return M
