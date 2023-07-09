---@type LazySpec
local spec = {
  "monaqa/dial.nvim",
  config = function()
    kyoh86.ensure("dial.map", function(m)
      vim.keymap.set("n", "<C-a>", m.inc_normal())
      vim.keymap.set("n", "<C-x>", m.dec_normal())
      vim.keymap.set("n", "g<C-a>", m.inc_gnormal())
      vim.keymap.set("n", "g<C-x>", m.dec_gnormal())
      vim.keymap.set("v", "<C-a>", m.inc_visual())
      vim.keymap.set("v", "<C-x>", m.dec_visual())
      vim.keymap.set("v", "g<C-a>", m.inc_gvisual())
      vim.keymap.set("v", "g<C-x>", m.dec_gvisual())
    end)
  end,
  keys = {
    { "<C-a>", mode = { "n", "v" } },
    { "<C-x>", mode = { "n", "v" } },
    { "g<C-a>", mode = { "n", "v" } },
    { "g<C-x>", mode = { "n", "v" } },
  },
}
return spec
