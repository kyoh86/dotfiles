---@type LazySpec[]
local spec = {
  {
    "lambdalisue/readablefold.vim",
    event = { "InsertEnter", "BufReadPre" },
  },
  {
    "petertriho/nvim-scrollbar",
    enabled = false,
    config = function()
      require("scrollbar").setup({
        handlers = {
          cursor = false,
        },
      })
    end,
    dependencies = { "kyoh86/momiji" }, -- depends for "search" handlers
  },
}
return spec
