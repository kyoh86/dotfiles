---@type LazySpec
local spec = {
  "vito-c/jq.vim",
  config = function()
    table.insert(vim.g.markdown_fenced_languages, "jq")
  end,
}
return spec
