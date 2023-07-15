local volaterm = require("kyoh86.lib.volatile_terminal")

vim.api.nvim_buf_create_user_command(0, "DenoUpdate", function()
  volaterm.split(10, "horizontal", { exec = "udd " .. vim.fn.shellescape(vim.fn.expand("%")), keep = true })
end, {})
vim.api.nvim_buf_create_user_command(0, "DenoCache", function()
  volaterm.split(10, "horizontal", { exec = "deno cache " .. vim.fn.shellescape(vim.fn.expand("%")), keep = true })
end, {})
