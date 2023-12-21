---@type LazySpec
local spec = {
  "github/copilot.vim",
  init = function()
    vim.g.copilot_filetypes = {
      ["ddu-ff-filter"] = false,
    }
  end,
}
return spec
