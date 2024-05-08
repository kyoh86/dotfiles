---@type LazySpec[]
local spec = {
  {
    "lambdalisue/vim-readablefold",
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
    dependencies = { "momiji" }, -- depends for "search" handlers
  },
}
return spec
