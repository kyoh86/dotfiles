local M = {}

function M.focus_nvim_pane()
  if vim.env.TMUX_PANE == nil or vim.env.TMUX_PANE == "" then
    return
  end
  pcall(function()
    vim.system({ "tmux", "select-pane", "-t", vim.env.TMUX_PANE }):wait()
  end)
end

function M.pane_count()
  if not vim.env.TMUX then
    return 0
  end
  local result = vim.system({ "tmux", "list-panes", "-F", "#{pane_id}" }, { text = true }):wait()
  if result.code ~= 0 then
    return 0
  end
  local count = 0
  for line in vim.gsplit(result.stdout, "\n", { plain = true, trimempty = true }) do
    if line ~= "" then
      count = count + 1
    end
  end
  return count
end

return M
