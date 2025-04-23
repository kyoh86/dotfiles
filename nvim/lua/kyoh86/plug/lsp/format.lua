return function(bufnr)
  local vtsls = vim.lsp.get_clients({ bufnr = bufnr, name = "vtsls" })
  local name = #vtsls > 0 and "vtsls" or "efm"
  vim.lsp.buf.format({
    name = name,
    timeout_ms = 2000,
  })
end
