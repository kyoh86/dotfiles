---@type LazySpec
local spec = {
  "shellRaining/hlchunk.nvim",
  event = { "UIEnter" },
  config = function()
    local opt = {
      chunk = {
        enable = true,
        chars = {
          horizontal_line = "─",
          vertical_line = "│",
          left_top = "╭",
          left_bottom = "╰",
          right_arrow = "▶", -- U+25B6
        },
        use_treesitter = false,
      },
      indent = {
        enable = true,
        use_treesitter = false,
      },
      line_num = {
        enable = true,
        use_treesitter = false,
      },
      blank = {
        enable = true,
        use_treesitter = false,
      },
    }
    kyoh86.ensure("momiji", function(m)
      vim.print(m.colors.lightmagenta)
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
