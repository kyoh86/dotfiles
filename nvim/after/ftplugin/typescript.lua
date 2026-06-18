local tmux = require("kyoh86.lib.tmux")

vim.api.nvim_buf_create_user_command(0, "DenoCache", function()
  tmux.run({ "deno", "cache", vim.fn.shellescape(vim.fn.expand("%")) }, { quit = "wait" })
end, {})
