---@type LazySpec
local spec = {
  "shellRaining/hlchunk.nvim",
  event = { "UIEnter" },
  config = function()
    local opt = {
      chunk = {
        use_treesitter = false,
        chars = {
          horizontal_line = "─",
          vertical_line = "│",
          left_top = "╭",
          left_bottom = "╰",
          right_arrow = "▶", -- U+25B6
        },
      },
    }
    kyoh86.ensure("momiji", function(m)
      opt.chunk.style = {
        { fg = m.colors.lightmagenta },
      }
      opt.line_num = {
        style = m.colors.lightmagenta,
      }
    end)
    require("hlchunk").setup(opt)
  end,
}
return spec
