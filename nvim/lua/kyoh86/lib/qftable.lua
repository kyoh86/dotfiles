local M = {}

local titles = {
  bufnr = "Buffer",
  bufname = "Name",
  module = "Module",
  lnum = "Line",
  end_lnum = "End Line",
  col = "Column",
  end_col = "End Column",
  vcol = "Visual Column",
  nr = "Error Number",
  pattern = "Match Pattern",
  text = "Text",
  type = "Error Type",
  valid = "Valid Error",
}

local function value(item, column)
  if column == "bufname" then
    return item.bufnr > 0 and vim.fn.bufname(item.bufnr) or ""
  end
  if column == "vcol" or column == "valid" then
    return item[column] ~= 0 and "yes" or ""
  end
  return tostring(item[column] or "")
end

local function row(cells, widths)
  return "| " .. table.concat(
    vim
      .iter(cells)
      :enumerate()
      :map(function(index, text)
        return text .. string.rep(" ", widths[index] - vim.fn.strdisplaywidth(text))
      end)
      :totable(),
    " | "
  ) .. " |"
end

function M.show(opts)
  opts = opts or {}
  local columns = opts.columns or { "bufname", "lnum", "text" }
  local formatter = opts.formatter or "markdown"
  local output = opts.printer or "hnew"
  local printer, target = output:match("^([^:]+):?(.*)$")
  if formatter ~= "markdown" then
    error("Unknown QfTable formatter: " .. formatter, 0)
  end
  if not vim.list_contains({ "cur", "reg", "hnew", "vnew" }, printer) then
    error("Unknown QfTable printer: " .. output, 0)
  end
  if printer == "reg" and target ~= "" and not target:match("^[%w*+]$") then
    error("Invalid QfTable register: " .. target, 0)
  end

  local headers, widths = {}, {}
  for index, column in ipairs(columns) do
    headers[index] = assert(titles[column], "Unknown QfTable column: " .. column)
    widths[index] = math.max(3, #headers[index])
  end
  local rows = {}
  for _, item in ipairs(vim.fn.getqflist()) do
    local cells = {}
    for index, column in ipairs(columns) do
      local text = value(item, column):gsub("\\", "\\\\"):gsub("|", "\\|"):gsub("\r?\n", "<br>")
      cells[index] = text
      widths[index] = math.max(widths[index], vim.fn.strdisplaywidth(text))
    end
    rows[#rows + 1] = cells
  end

  local lines = { row(headers, widths) }
  lines[2] = row(
    vim.tbl_map(function(width)
      return string.rep("-", width)
    end, widths),
    widths
  )
  for _, cells in ipairs(rows) do
    lines[#lines + 1] = row(cells, widths)
  end

  if printer == "reg" then
    vim.fn.setreg(target ~= "" and target or '"', lines, "l")
  elseif printer == "cur" then
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, lnum, lnum, false, lines)
  else
    local args = target ~= "" and { target } or {}
    vim.api.nvim_cmd({ cmd = printer == "hnew" and "new" or "vnew", args = args }, {})
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  end
end

function M.command(command)
  local opts = {}
  for _, arg in ipairs(command.fargs) do
    local key, value = arg:match("^%-%-(%w+)=(.+)$")
    if key == "column" then
      opts.columns = opts.columns or {}
      table.insert(opts.columns, value)
    elseif key == "output" or key == "printer" then
      opts.printer = value
    elseif key == "format" or key == "formatter" then
      opts.formatter = value
    else
      error("Invalid QfTable option: " .. arg, 0)
    end
  end
  M.show(opts)
end

return M
