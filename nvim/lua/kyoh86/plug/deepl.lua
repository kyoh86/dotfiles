---@type LazySpec
local spec = {
  "ryicoh/deepl.vim",
  config = function()
    vim.g["deepl#endpoint"] = "https://api-free.deepl.com/v2/translate"
    vim.g["deepl#auth_key"] = "00000000-0000-0000-0000-000000000000:fx"

    -- replace a visual selection
    vim.keymap.set("v", "<leader>te", '<cmd>call deepl#v("EN")<cr>', { remap = false })
    vim.keymap.set("v", "<leader>tj", '<cmd>call deepl#v("JA")<cr>', { remap = false })
  end,
  keys = {
    { "<leader>te", '<cmd>call deepl#v("EN")<cr>', { mode = "v", remap = false } },
    { "<leader>tj", '<cmd>call deepl#v("JA")<cr>', { mode = "v", remap = false } },
  },
}
return spec
