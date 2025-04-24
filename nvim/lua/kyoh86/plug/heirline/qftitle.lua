return function()
  local title = vim.fn.getqflist({ title = true }).title
  if title == "" then
    return "Quickfix"
  end
  return title
end
