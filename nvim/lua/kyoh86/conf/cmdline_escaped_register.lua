-- Command line内でカーソル位置周りやレジスタのテキストをエスケープして貼り付ける処理群
local func = require("kyoh86.lib.func")

-- cmdtypeとcmdlineの内容に応じてエスケープして返す
local function escape(cmdtype, cmdline, str)
  if cmdtype == "/" or cmdtype == "?" then
    return vim.fn.escape(str, "/")
  elseif cmdtype == ":" and cmdline:sub(1, 1) == "!" then
    return vim.fn.shellescape(str)
  else
    return vim.fn.fnameescape(str)
  end
end

-- テキストをエスケープして現在のcmdに貼り付ける
-- @param text: string
local function put_escaped_cmdline(text)
  local cmdtype = vim.fn.getcmdtype()
  local cmdline = vim.fn.getcmdline()
  local cmdpos = vim.fn.getcmdpos()
  local escaped_text = escape(cmdtype, cmdline, text)
  local new_cmdline = cmdline:sub(1, cmdpos - 1) .. escaped_text .. cmdline:sub(cmdpos)
  vim.fn.setcmdline(new_cmdline, cmdpos + #escaped_text)
end

-- カーソル周りのテキストを取得する処理群
local scopes = {
  ["<C-f>"] = function()
    return vim.fn.expand("<cfile>")
  end,
  ["<C-p>"] = function()
    return vim.fn.findfile(vim.fn.expand("<cfile>"))
  end,
  ["<C-w>"] = function()
    return vim.fn.expand("<cword>")
  end,
  ["<C-a>"] = function()
    return vim.fn.expand("<cWORD>")
  end,
  ["<C-l>"] = function()
    return vim.fn.getline(".")
  end,
}

-- カーソル周りのテキストをエスケープして現在のcmdに貼り付ける
-- @param kind: "file"|"path"|"word"|"WORD"|"line"
local function put_cmdline_scope(kind)
  put_escaped_cmdline(scopes[kind]())
end

-- レジスタのテキストをエスケープして現在のcmdに貼り付ける
-- @param regname: string
local function put_cmdline_register(regname)
  put_escaped_cmdline(vim.fn.getreg(regname))
end

local keymap_prefix = "<C-r><C-r>"

for key in pairs(scopes) do
  vim.keymap.set("c", keymap_prefix .. key, func.bind_all(put_cmdline_scope, key), {})
end

local registers = vim.tbl_flatten({
  { [[a]], [[b]], [[c]], [[d]], [[e]], [[f]], [[g]], [[h]], [[i]], [[j]], [[k]], [[l]], [[m]] },
  { [[n]], [[o]], [[p]], [[q]], [[r]], [[s]], [[t]], [[u]], [[v]], [[w]], [[x]], [[y]], [[z]] },
  { [[A]], [[B]], [[C]], [[D]], [[E]], [[F]], [[G]], [[H]], [[I]], [[J]], [[K]], [[L]], [[M]] },
  { [[N]], [[O]], [[P]], [[Q]], [[R]], [[S]], [[T]], [[U]], [[V]], [[W]], [[X]], [[Y]], [[Z]] },
  { [[0]], [[1]], [[2]], [[3]], [[4]], [[5]], [[6]], [[7]], [[8]], [[9]] },
  { [["]], [[-]], [[:]], [[.]], [[%]], [[#]], [[=]], [[*]], [[+]], [[_]], [[/]] },
})

for _, regname in ipairs(registers) do
  vim.keymap.set("c", keymap_prefix .. regname, func.bind_all(put_cmdline_register, regname), {})
end
