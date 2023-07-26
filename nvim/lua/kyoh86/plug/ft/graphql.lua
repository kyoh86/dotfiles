---@type LazySpec
local spec = {
  "jparise/vim-graphql",
  config = function()
    table.insert(vim.g.markdown_fenced_languages, "graphql")
  end,
}
return spec
