local glaze = require("kyoh86.lib.glaze")
local mise_path = glaze.ensure("mise-path", function()
  return vim.fn.exepath("mise")
end)
vim.g.nvim_proxy_deno_command = { mise_path, "exec", "deno", "--", "deno" }
