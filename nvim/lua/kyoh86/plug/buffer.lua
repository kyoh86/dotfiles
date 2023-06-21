--- バッファ操作系
local keep = function()
  require("wipeout").menu({ keep_layout = true })
end

---@type LazySpec[]
local spec = {
  {
    "kyoh86/curtain.nvim",
    keys = {
      { "<leader>wr", "<plug>(curtain-start)", desc = "resize current window" },
    },
  },
  {
    "kyoh86/wipeout-buffers.nvim",
    keys = {
      {
        "<C-q>",
        function()
          require("wipeout").menu()
        end,
        silent = true,
        desc = "show the menu to wipeout buffers",
      },
      { "<A-q>", keep, silent = true, desc = "show the menu to wipeout buffers without closing windcow" },
      { "<C-S-q>", keep, silent = true, desc = "show the menu to wipeout buffers without closing windcow" },
    },
  },
}
return spec
