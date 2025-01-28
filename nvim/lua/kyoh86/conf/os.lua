local glaze = require("kyoh86.lib.glaze")
glaze.glaze("os_uname_sysname", function()
  return vim.uv.os_uname()
end)
