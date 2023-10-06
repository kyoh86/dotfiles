---@type LazySpec
local spec = {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  opts = {
    indent = {
      highlight = "MomijiGrayscale1",
    },
    exclude = {
      buftypes = { "terminal", "nofile" },
    },
  },
  config = function(_, opts)
    local hooks = require("ibl.hooks")
    hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
    require("ibl").setup(opts)
  end,
}
return spec
