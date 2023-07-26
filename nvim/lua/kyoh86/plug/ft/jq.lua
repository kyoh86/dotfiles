---@type LazySpec
local spec = {
  "bfrg/vim-jq",
  config = function()
    table.insert(vim.g.markdown_fenced_languages, "jq")
  end,
}
return spec
