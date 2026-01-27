--- 外部で開く方法を設定する
local glaze = require("kyoh86.lib.glaze")
glaze.glaze("opener", function()
  if vim.fn.executable("wslview") ~= 0 then
    return "wslview"
  elseif vim.fn.executable("xdg-open") ~= 0 then
    return "xdg-open"
  elseif vim.fn.executable("open") ~= 0 then
    return "open"
  end
  return ""
end)
