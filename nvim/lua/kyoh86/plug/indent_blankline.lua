---@type LazySpec
local spec = {
  "lukas-reineke/indent-blankline.nvim",
  opts = {
    show_first_indent_level = false,
    buftype_exclude = { "terminal", "nofile" },
  },
  event = "VeryLazy",
  config = function(_, opts)
    vim.api.nvim_set_hl(0, "IndentBlanklineChar", { link = "MomijiGrayscale1" })
    require("indent_blankline").setup(opts)
  end,
}
return spec
