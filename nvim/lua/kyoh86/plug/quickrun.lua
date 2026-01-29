--- Quickrunの設定
local qr_config = {
  mongo = {
    command = "mongosh",
    cmdopt = "--nodb --quiet",
    runner = "terminal",
  },
  lua = {
    type = "lua/vim",
    outputter = "message",
  },
  vim = {
    command = "source",
    runner = "vimscript",
    outputter = "message",
  },
}
vim.g.quickrun_config = qr_config
vim.g.quickrun_no_default_key_mappings = 1

local map = function()
  vim.keymap.set({ "n", "v" }, "<leader>xx", "<plug>(quickrun)", { remap = false, buffer = true, desc = "execute the current buffer with quickrun" })
end

local au = require("kyoh86.lib.autocmd")
local group = au.group("kyoh86.plug.quickrun", true)
group:hook("BufRead", {
  pattern = "*.mongo.js",
  callback = function()
    vim.b.quickrun_config = { type = "mongo" }
    map()
  end,
})

for ft in pairs(qr_config) do
  group:hook("FileType", {
    pattern = ft,
    callback = map,
  })
end

---@type LazySpec
local spec = {
  "thinca/vim-quickrun",
}
return spec
