local M = {}

local cache = {}

local function detect(path)
  local filetype = vim.filetype.match({ filename = path })
  if filetype then
    return filetype
  end

  -- vim.filetype.match is not guaranteed to work on filename alone (see https://github.com/neovim/neovim/issues/27265)
  local bufnr = vim.fn.bufnr(path)
  if bufnr ~= -1 then
    return vim.filetype.match({ buf = bufnr })
  end

  local bufn = vim.fn.bufadd(path)
  vim.fn.bufload(bufn)
  filetype = vim.filetype.match({ buf = bufn })
  vim.api.nvim_buf_delete(bufn, { force = true })
end

function M.get(path)
  if cache[path] then
    return cache[path]
  end

  local filetype = detect(path)
    cache[path] = filetype
  return filetype
end

return M
