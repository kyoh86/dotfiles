---@type LazySpec[]
local spec = {
  { "dhruvasagar/vim-table-mode", ft = "markdown" },
  {
    "previm/previm", -- previous some file-types
    dependencies = { "open-browser.vim" },
  },
}
return spec
