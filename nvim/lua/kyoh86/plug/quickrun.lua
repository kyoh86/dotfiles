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

local group = vim.api.nvim_create_augroup("kyoh86-plug-quickrun", { clear = true })
vim.api.nvim_create_autocmd("BufRead", {
  pattern = "*.mongo.js",
  group = group,
  callback = function()
    vim.b.quickrun_config = { type = "mongo" }
    map()
  end,
})

for ft in pairs(qr_config) do
  vim.api.nvim_create_autocmd("FileType", {
    pattern = ft,
    group = group,
    callback = map,
  })
end

---@type LazySpec
local spec = {
  "thinca/vim-quickrun",
}
return spec
