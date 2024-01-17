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

---@param n number|nil
local function column_itoa(n)
  if n == nil then
    return ""
  end
  return string.format("%d", n)
end

---@param b boolean|nil
local function column_btoa(b)
  if b == nil then
    return ""
  end
  if b then
    return "yes"
  end
  return ""
end

---@param s string|nil
local function column_raw(s)
  if s == nil then
    return ""
  end
  return s
end

---@class QuickfixColumn
---@field source string  Column source
---@field postprocess fun(n: any): string
---@field title string  Title
---@field length? number  A length to display

---@type table<string, QuickfixColumn>
local VALID_COLUMNS = {
  bufnr = { --number of buffer
    source = "bufnr",
    postprocess = column_itoa,
    title = "Buffer",
  },
  bufname = { -- name of the buffer (file name)
    source = "bufnr",
    postprocess = function(nr)
      return vim.fn.bufname(nr)
    end,
    title = "Name",
  },
  module = { --module name
    source = "module",
    postprocess = column_raw,
    title = "Module",
  },
  lnum = { --line number in the buffer (first line is 1)
    source = "lnum",
    postprocess = column_itoa,
    title = "Line",
  },
  end_lnum = { --end of line number if the item is multiline
    source = "end_lnum",
    postprocess = column_itoa,
    title = "End Line",
  },
  col = { --column number (first column is 1)
    source = "col",
    postprocess = column_itoa,
    title = "Column",
  },
  end_col = { --end of column number if the item has range
    source = "end_col",
    postprocess = column_itoa,
    title = "End Column",
  },
  vcol = { --|TRUE|: "col" is visual column:|FALSE|: "col" is byte index
    source = "vcol",
    postprocess = column_btoa,
    title = "Visual Column",
  },
  nr = { --error number
    source = "nr",
    postprocess = column_itoa,
    title = "Error Number",
  },
  pattern = { --search pattern used to locate the error
    source = "pattern",
    postprocess = column_raw,
    title = "Match Pattern",
  },
  text = { --description of the error
    source = "text",
    postprocess = column_raw,
    title = "Text",
  },
  type = { --type of the error, 'E', '1', etc.
    source = "type",
    postprocess = column_raw,
    title = "Error Type",
  },
  valid = { --|TRUE|: recognized error message
    source = "valid",
    postprocess = column_btoa,
    title = "Valid Error",
  },
}

---@type string[]
local DEFAULT_COLUMN_NAMES = { "bufname", "lnum", "text" }

-- フォーマット

--- Markdown形式でフォーマットする
---@param printer Printer
---@param columns QuickfixColumn[]
---@param rows string[][])>
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

---@type table<string, fun(printer: Printer, columns: QuickfixColumn[], rows: string[][])>
local VALID_FORMATS = {
  markdown = format_markdown,
}

local DEFAULT_FORMAT = "markdown"

--- 出力先

---@class Printer
local Printer = {}

---@param target string  Output target
function Printer:open(target)
  error("not implemented: " .. target)
end

---@param text string  Output value
function Printer:put(text)
  error("not implemented: " .. text)
end

---@class CurPrinter : Printer
local CurPrinter = {}

---@return CurPrinter
function CurPrinter.new()
  return setmetatable({ line = vim.fn.line(".") }, { __index = CurPrinter })
end

function CurPrinter:open(_) end

---@param text string  Output value
function CurPrinter:put(text)
  vim.fn.append(self.line, text)
  self.line = self.line + 1
end

---@class BufPrinter : Printer
---@field cmd fun(target?: string)  A command to open new buffer window
local BufPrinter = {}
---@return BufPrinter
function BufPrinter.hnew()
  return setmetatable({ line = 1, cmd = vim.cmd.new }, { __index = BufPrinter })
end
---@return BufPrinter
function BufPrinter.vnew()
  return setmetatable({ line = 1, cmd = vim.cmd.vnew }, { __index = BufPrinter })
end

---@param target string  Output target
function BufPrinter:open(target)
  if target == "" then
    self.cmd()
  else
    self.cmd(target)
  end
end

---@param text string  Output value
function BufPrinter:put(text)
  vim.fn.setline(self.line, text)
  self.line = self.line + 1
end

---@class RegPrinter : Printer
local RegPrinter = {}
---@return RegPrinter
function RegPrinter.new()
  return setmetatable({ line = 1, option = "l" }, { __index = RegPrinter })
end

---@type object
local valid_reg = vim.regex([[^[a-zA-Z0-9\*+]$]])

---@param target string  Output target
function RegPrinter:open(target)
  if target ~= "" and not valid_reg:match_str(target) then
    error(string.format("invalid argument: %q is not valid register name", target))
  end
  self.regname = target
end

---@param text string  Output value
function RegPrinter:put(text)
  vim.fn.setreg(self.regname, text, self.option)
  self.option = self.option .. "a"
end

---@type table<string, fun(): Printer>
local VALID_OUTPUTS = {
  cur = CurPrinter.new, -- vim.fn.append()
  hnew = BufPrinter.hnew, -- vim.cmd.new, vim.fn.setline()
  vnew = BufPrinter.vnew, -- vim.cmd.vnew, vim.fn.setline()
  reg = RegPrinter.new, -- vim.fn.setreg("?", line, "la"),
}

local DEFAULT_OUTPUT = BufPrinter.hnew

-- 処理本体
local function quickfix_to_table(event)
  local format = DEFAULT_FORMAT
  local columnNames = DEFAULT_COLUMN_NAMES
  local printerFactory = DEFAULT_OUTPUT
  local name = ""
  for _, arg in pairs(event.fargs) do
    if vim.startswith(arg, "-format=") then
      format = string.sub(arg, 9)
    elseif vim.startswith(arg, "-column=") then
      columnNames = vim.split(string.sub(arg, 9), ",", { trimempty = true, plain = true })
    elseif vim.startswith(arg, "-output=") then
      local terms = vim.split(string.sub(arg, 9), ":", { trimempty = true, plain = true })
      printerFactory = VALID_OUTPUTS[terms[1]]
      if not printerFactory then
        error(string.format("invalid argument: %q is not valid printer name"))
      end
      if #terms >= 2 then
        name = terms[2]
      end
    end
  end
  ---@type QuickfixColumn[]
  local columns = vim.tbl_map(function(c)
    local column = VALID_COLUMNS[c]
    if not column then
      error(string.format("invalid argument: %q is not valid column name", c))
    end
    return vim.tbl_deep_extend("force", { length = #column.title }, column)
  end, columnNames)
  local formatter = VALID_FORMATS[format]
  if not formatter then
    error(string.format("invalid argument: %q is no valid format", format))
  end
  ---@type string[][]
  local rows = {}
  for _, item in ipairs(vim.fn.getqflist()) do
    ---@type string[]
    local cells = {}
    for c, column in ipairs(columns) do
      local v = column.postprocess(vim.tbl_get(item, column.source))
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
vim.api.nvim_create_user_command("QfTable", quickfix_to_table, { force = true, range = true, nargs = "*", desc = "QuickfixのリストをMarkdownのテーブルとして入力する" })
vim.cmd([[ cabbrev <expr> Qftable (getcmdtype() ==# ":" && getcmdline() ==# "Qftable") ? "QfTable" : "Qftable" ]])
vim.keymap.set({ "n", "v" }, "<leader>qt", "<cmd>QfTable<cr>", { remap = false, desc = "QuickfixのリストをMarkdownのテーブルとして入力する" })
