local M = {}

function M.diagnostics(bufnr, severity)
  local args = {}
  if severity and severity ~= "" then
    args.severity = vim.diagnostic.severity[string.upper(severity)]
  end
  local list = vim.diagnostic.get(bufnr or 0, args)
  local result = {}
  for _, item in ipairs(list) do
    result[#result + 1] = {
      bufnr = item.bufnr,
      lnum = item.lnum,
      col = item.col,
      end_lnum = item.end_lnum,
      end_col = item.end_col,
      severity = item.severity,
      severity_name = vim.diagnostic.severity[item.severity],
      message = item.message,
      source = item.source,
      code = item.code,
    }
  end
  return result
end

return M
