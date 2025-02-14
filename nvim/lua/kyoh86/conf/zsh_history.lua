local bit = require("bit")

-- unmetafy関数の実装
local function unmetafy(data)
  local result = ""
  local change = false
  for i = 1, #data do
    local b = string.byte(data, i)
    if b == 0x83 then
      change = true
    else
      if change then
        b = bit.bxor(b, 0x20)
      end
      result = result .. string.char(b)
      change = false
    end
  end
  return result
end

-- metafy関数の実装
local function metafy(data)
  local result = ""
  for i = 1, #data do
    local b = string.byte(data, i)
    if b == 0 or (0x83 <= b and b <= 0xa2) then
      result = result .. string.char(0x83) .. string.char(bit.bxor(b, 0x20))
    else
      result = result .. string.char(b)
    end
  end
  return result
end

local M = {}

-- 読み込み時にunmetafyする関数
function M.read_zsh_history()
  local filepath = vim.fn.expand("%:p")
  local file = io.open(filepath, "rb")
  if file then
    local data = file:read("*all")
    file:close()
    local unmetafied_data = unmetafy(data)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(unmetafied_data, "\n"))
    vim.bo.modified = false -- バッファを未変更状態に設定
  end
end

-- 保存時にmetafyする関数
function M.write_zsh_history()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local data = table.concat(lines, "\n")
  local metafied_data = metafy(data)
  local filepath = vim.fn.expand("%:p")
  local file = io.open(filepath, "wb")
  if file then
    file:write(metafied_data)
    file:close()
  end
  vim.bo.modified = false -- バッファを未変更状態に設定
end

return M
