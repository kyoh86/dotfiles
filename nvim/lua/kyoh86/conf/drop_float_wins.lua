--- Workaround: some plugins may fail to drop windows (very rarely).
--- it closes all float windows.
---@param force boolean
local function close_floating_window(force)
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    local conf = vim.api.nvim_win_get_config(winid)
    local rel = vim.tbl_get(conf, "relative")
    if rel and rel ~= nil and rel ~= "" then -- only floating window
      vim.api.nvim_win_close(winid, force)
    end
  end
end

vim.api.nvim_create_user_command("CloseFloatingWindows", function(args)
  close_floating_window(args.bang)
end, { desc = "Workaround: some plugins may fail to drop windows (very rarely)" })
