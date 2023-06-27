local M = {}

--- 現在のバッファが無名の空バッファかどうかを取得する
---@return boolean
function M.current()
  local name = vim.api.nvim_buf_get_name(0)
  if name ~= "" then
    return false
  end
  local prof = vim.fn.wordcount()
  return prof.bytes == 0
end

return M
