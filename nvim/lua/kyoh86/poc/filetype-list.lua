local M = {}

function M.list_filetypes_from_rtp()
  local rtp = vim.opt.runtimepath:get()
  local seen = {}
  for _, path in ipairs(rtp) do
    local ft_dirs = vim.fn.globpath(path, "ftplugin/*.vim", false, true)
    local lua_dirs = vim.fn.globpath(path, "ftplugin/*.lua", false, true)
    for _, f in ipairs(ft_dirs) do
      local ft = vim.fn.fnamemodify(f, ":t:r")
      seen[ft] = true
    end
    for _, f in ipairs(lua_dirs) do
      local ft = vim.fn.fnamemodify(f, ":t:r")
      seen[ft] = true
    end
  end
  local list = vim.tbl_keys(seen)
  table.sort(list)

  if #list == 0 then
    list = { "(no filetypes found)" }
  end

  local max_len = 0
  for _, ft in ipairs(list) do
    if #ft > max_len then
      max_len = #ft
    end
  end

  local height = math.min(#list, math.max(1, math.floor(vim.o.lines * 0.6)))
  local width = math.min(max_len + 2, math.max(20, math.floor(vim.o.columns * 0.6)))
  local row = math.floor((vim.o.lines - height) / 2 - 1)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, list)
  vim.bo[buf].modifiable = false

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "single",
  })

  return buf, win
end

return M
