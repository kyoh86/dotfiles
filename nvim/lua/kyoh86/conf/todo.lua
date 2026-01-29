vim.keymap.set("n", "<leader>tit", [[<cmd>Ripgrep -i to]] .. [[do<cr>]], { remap = false, desc = "To" .. "Doを検索する" })
vim.keymap.set("n", "<leader><leader>t", [[<cmd>lua require("kyoh86.conf.todo").open_note()<cr>]], { remap = false, desc = "作業メモを編集する" })
local filename = vim.fn.expand("~/.local/state/to" .. "do.md")
local splitdrop = require("kyoh86.conf.splitdrop")
local func = require("kyoh86.lib.func")

local au = require("kyoh86.lib.autocmd")
au.group("kyoh86.conf.todo", true):hook({ "BufReadPost", "BufNewFile" }, {
  pattern = "to" .. "do.md",
  callback = function(ctx)
    if ctx.file == filename then
      vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = ctx.buf })
    end
  end,
})
return {
  open_note = func.bind_all(splitdrop, filename),
}
