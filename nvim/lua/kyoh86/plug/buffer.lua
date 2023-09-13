--- バッファ操作系
local keep = function()
  require("unload").menu({ keep_layout = true })
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
    "kyoh86/unload-buffers.nvim",
    keys = {
      {
        "<C-q>",
        function()
          require("unload").menu()
        end,
        silent = true,
        desc = "show the menu to unload buffers",
      },
      { "<A-q>", keep, silent = true, desc = "show the menu to unload buffers without closing windcow" },
      { "<C-S-q>", keep, silent = true, desc = "show the menu to unload buffers without closing windcow" },
    },
  },
}
return spec
