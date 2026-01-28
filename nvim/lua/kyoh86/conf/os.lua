local glaze = require("kyoh86.lib.glaze")
glaze.ensure("os_uname_sysname", function()
  return vim.uv.os_uname()
end)
