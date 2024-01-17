--- バッファ操作系
local keep = function()
  require("bdelete").menu({ keep_layout = true })
end

---@type LazySpec[]
local spec = {
  {
    "kyoh86/bdelete-buffers.nvim",
    keys = {
      {
        "<C-q>",
        function()
          require("bdelete").menu()
        end,
        silent = true,
        desc = "バッファを閉じる",
      },
      { "<A-q>", keep, silent = true, desc = "Windowを閉じずにバッファを閉じる" },
    },
  },
}
return spec
