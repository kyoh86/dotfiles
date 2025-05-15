return {
  provider = function()
    return "[" .. vim.fn.bufnr("%") .. "]"
  end,
}
