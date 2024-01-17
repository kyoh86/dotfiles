local function get_winopts(output)
  local height = #output
  local width = 1
  for _, line in ipairs(output) do
    local newWidth = vim.fn.strdisplaywidth(line) --[[@as integer]]
    if newWidth > width then
      width = newWidth
    end
  end
  return {
    height = height,
    width = width,
  }
end

local winid = -1
local function close_popup()
  if winid < 0 then
    return
  end
  vim.api.nvim_win_close(winid, true)
  winid = -1
end

local function show_context()
  kyoh86.ensure("nvim-navic", function(m)
    local bufnr = vim.fn.bufnr()
    if not m.is_available(bufnr) then
      vim.notify("nvim-navic is not available for this buffer", vim.log.levels.WARN)
      return
    end
    local output = vim.split(m.get_location({ separator = "\30" }, bufnr), "\30", { plain = true }) -- \30 is RS (record separator)
    for i, line in ipairs(output) do
      output[i] = line:gsub("^", string.rep("\t", i - 1))
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, output)
    local opts = get_winopts(output)
    opts["relative"] = "cursor"
    opts["col"] = 1
    opts["row"] = 1
    opts["anchor"] = "NW"
    opts["style"] = "minimal"
    opts["border"] = "single"
    winid = vim.api.nvim_open_win(buf, false, opts)
    -- close popup when cursor moved
    vim.api.nvim_set_option_value("winhl", "NormalFloat:Normal,FloatBorder:Normal", { scope = "local", win = winid })
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = vim.api.nvim_create_augroup("kyoh86-plug-lsp-context", { clear = true }),
      once = true,
      callback = close_popup,
    })
  end)
end

return function()
  vim.keymap.set("n", "<leader>lic", show_context, { desc = "現在位置のコンテキストを表示する" })
end
