--- Statuslineの設定

return {
  provider = function()
    return string.rep("─", vim.api.nvim_win_get_width(0) / vim.fn.strdisplaywidth("─"))
  end,
  hl = function(self)
    return { fg = "brightwhite", bg = "black" }
  end,
}
