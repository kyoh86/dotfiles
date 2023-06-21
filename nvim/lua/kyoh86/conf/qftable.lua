---Quickfixの中身を表として出力する
--- Synopsis
---    :QfTable
---    :QfTable -format=markdown -column=bufname,lnum,text -output=reg:*
--- Arguments
---    -format 出力フォーマットを指定する。markdownのみ対応。 default: markdown
---    -column 各列に出力する要素をカンマ(,)つなぎで指定する。 default: bufname,lnum,text
---              指定出来る要素: name, bufname, module, lnum, end_lnum, col, end_col, vcol, nr, pattern, text, type, valid
---    -output 出力先を指定する。 default: hnew
---              出力先には以下の4種類を指定出来る。
---              - cur          カーソル行の下に追記する
---              - hnew[:name]  横分割で新しいバッファ・ウインドウを開いて記入する。 :name のようにコロンに続けてバッファ名を指定出来る。
---              - vnew[:name]  縦分割で新しいバッファ・ウインドウを開いて記入する。 :name のようにコロンに続けてバッファ名を指定出来る。
---              - reg[:name]   レジスタ |registers| に書き込む。`:a`や`:A`のようにコロンに続けてレジスタ名を指定できる。省略した場合はunnamed registerに書き込む。

-- Columnの表現
local function column_itoa(n)
  if n == nil then
    return ""
  end
  return string.format("%d", n)
end

local function column_btoa(b)
  if b == nil then
    return ""
  end
  if b then
    return "yes"
  end
  return ""
end

local function column_raw(s)
  if s == nil then
    return ""
  end
  return s
end

local valid_columns = {
  bufnr = { --number of buffer
    name = "bufnr",
    postprocess = column_itoa,
    title = "Buffer",
  },
  bufname = { -- name of the buffer (file name)
    name = "bufnr",
    postprocess = function(nr)
      return vim.fn.bufname(nr)
    end,
    title = "Name",
  },
  module = { --module name
    name = "module",
    postprocess = column_raw,
    title = "Module",
  },
  lnum = { --line number in the buffer (first line is 1)
    name = "lnum",
    postprocess = column_itoa,
    title = "Line",
  },
  end_lnum = { --end of line number if the item is multiline
    name = "end_lnum",
    postprocess = column_itoa,
    title = "End Line",
  },
  col = { --column number (first column is 1)
    name = "col",
    postprocess = column_itoa,
    title = "Column",
  },
  end_col = { --end of column number if the item has range
    name = "end_col",
    postprocess = column_itoa,
    title = "End Column",
  },
  vcol = { --|TRUE|: "col" is visual column:|FALSE|: "col" is byte index
    name = "vcol",
    postprocess = column_btoa,
    title = "Visual Column",
  },
  nr = { --error number
    name = "nr",
    postprocess = column_itoa,
    title = "Error Number",
  },
  pattern = { --search pattern used to locate the error
    name = "pattern",
    postprocess = column_raw,
    title = "Match Pattern",
  },
  text = { --description of the error
    name = "text",
    postprocess = column_raw,
    title = "Text",
  },
  type = { --type of the error, 'E', '1', etc.
    name = "type",
    postprocess = column_raw,
    title = "Error Type",
  },
  valid = { --|TRUE|: recognized error message
    name = "valid",
    postprocess = column_btoa,
    title = "Valid Error",
  },
}

local default_columns = { "bufname", "lnum", "text" }

-- フォーマット
local function format_markdown(printer, columns, rows)
  printer:put("| " .. table.concat(
    vim.tbl_map(function(col)
      return col.title .. string.rep(" ", col.length - #col.title)
    end, columns),
    " | "
  ) .. " |")
  printer:put("| " .. table.concat(
    vim.tbl_map(function(col)
      return "-" .. string.rep(" ", col.length - 1)
    end, columns),
    " | "
  ) .. " |")
  for _, row in ipairs(rows) do
    local cells = {}
    for c, cell in ipairs(row) do
      local col = columns[c]
      table.insert(cells, cell .. string.rep(" ", col.length - #cell))
    end
    printer:put("| " .. table.concat(cells, " | ") .. " |")
  end
end

local valid_formats = {
  markdown = format_markdown,
}

local default_format = "markdown"

-- 出力先
local CurPrinter = {}
function CurPrinter.new()
  return setmetatable({ line = vim.fn.line(".") }, { __index = CurPrinter })
end

function CurPrinter:open(_) end

function CurPrinter:put(text)
  vim.fn.append(self.line, text)
  self.line = self.line + 1
end

local BufPrinter = {}
function BufPrinter.hnew()
  return setmetatable({ line = 1, cmd = vim.cmd.new }, { __index = BufPrinter })
end
function BufPrinter.vnew()
  return setmetatable({ line = 1, cmd = vim.cmd.vnew }, { __index = BufPrinter })
end

function BufPrinter:open(name)
  if name == "" then
    self.cmd()
  else
    self.cmd(name)
  end
end

function BufPrinter:put(text)
  vim.fn.setline(self.line, text)
  self.line = self.line + 1
end

local RegPrinter = {}
function RegPrinter.new()
  return setmetatable({ line = 1, option = "l" }, { __index = RegPrinter })
end

local valid_reg = vim.regex([[^[a-zA-Z0-9\*+]$]])
function RegPrinter:open(name)
  if name ~= "" and not valid_reg:match_str(name) then
    error(string.format("invalid argument: %q is not valid register name", name))
  end
  self.regname = name
end

function RegPrinter:put(text)
  vim.fn.setreg(self.regname, text, self.option)
  self.option = self.option .. "a"
end

local valid_outputs = {
  cur = CurPrinter.new, -- vim.fn.append()
  hnew = BufPrinter.hnew, -- vim.cmd.new, vim.fn.setline()
  vnew = BufPrinter.vnew, -- vim.cmd.vnew, vim.fn.setline()
  reg = RegPrinter.new, -- vim.fn.setreg("?", line, "la"),
}

local default_output = BufPrinter.hnew

-- 処理本体
local function quickfix_to_table(event)
  local format = default_format
  local columns = default_columns
  local printerFactory = default_output
  local name = ""
  for _, arg in pairs(event.fargs) do
    if vim.startswith(arg, "-format=") then
      format = string.sub(arg, 9)
    elseif vim.startswith(arg, "-column=") then
      columns = vim.split(string.sub(arg, 9), ",", { trimempty = true, plain = true })
    elseif vim.startswith(arg, "-output=") then
      local terms = vim.split(string.sub(arg, 9), ":", { trimempty = true, plain = true })
      printerFactory = valid_outputs[terms[1]]
      if not printerFactory then
        error(string.format("invalid argument: %q is not valid printer name"))
      end
      if #terms >= 2 then
        name = terms[2]
      end
    end
  end
  columns = vim.tbl_map(function(c)
    local column = valid_columns[c]
    if not column then
      error(string.format("invalid argument: %q is not valid column name", c))
    end
    return vim.tbl_deep_extend("force", { length = #column.title }, column)
  end, columns)
  local formatter = valid_formats[format]
  if not formatter then
    error(string.format("invalid argument: %q is no valid format", format))
  end
  local rows = {}
  for _, item in ipairs(vim.fn.getqflist()) do
    local cells = {}
    for c, column in ipairs(columns) do
      local v = column.postprocess(vim.fn.get(item, column.name, ""))
      columns[c].length = math.max(columns[c].length, #v)
      table.insert(cells, v)
    end
    table.insert(rows, cells)
  end
  local printer = printerFactory()
  printer:open(name)
  formatter(printer, columns, rows)
end

-- コマンド/keymap設定
vim.api.nvim_create_user_command("QfTable", quickfix_to_table, { force = true, range = true, nargs = "*" })
vim.cmd([[ cabbrev <expr> Qftable (getcmdtype() ==# ":" && getcmdline() ==# "Qftable") ? "QfTable" : "Qftable" ]])
vim.keymap.set({ "n", "v" }, "<leader>qt", "<cmd>QfTable<cr>", { remap = false })
