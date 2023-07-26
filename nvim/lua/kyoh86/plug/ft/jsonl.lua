---@type LazySpec
local spec = {
  "kyoh86/vim-jsonl",
  config = function()
    table.insert(vim.g.markdown_fenced_languages, "jsonl")
  end,
}
return spec
