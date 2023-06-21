--- 言語の設定
vim.opt.encoding = "utf-8"
vim.opt.helplang = { "ja", "en" }
vim.cmd("language messages en_US.UTF-8")

--- 細々した挙動を変えるオプション
vim.opt.number = true -- Show the line number
vim.opt.numberwidth = 2
vim.opt.showcmd = true
vim.opt.showtabline = 1
vim.opt.scrolloff = 3 -- Show least &scrolloff lines before/after cursor
vim.opt.sidescrolloff = 3
vim.opt.signcolumn = "auto"

--- マウスを無効化
vim.opt.mouse = {}

--- ウインドウタイトルをCWDのBasenameにする
vim.opt.title = true
vim.opt.titlestring = "%(%{fnamemodify(getcwd(),':t')}%)"

--- 編集中のバッファをWindowから外せるようにする
vim.opt.hidden = true

--- 履歴件数
vim.opt.history = 10000

--- インデント設定
local indent_size = 4
vim.opt.tabstop = indent_size
vim.opt.shiftwidth = indent_size
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.autoindent = true

--- Wrapping設定
vim.opt.wrap = false
vim.opt.textwidth = 0 -- never limit length of each line

--- テキスト表示の設定
vim.opt.ambiwidth = "single"
vim.opt.emoji = true -- Show emoji characters
vim.opt.conceallevel = 0
vim.opt.foldmethod = "manual"
vim.opt.list = true
vim.opt.listchars = {
  tab = "» ",
  trail = "▫",
  eol = "↵",
  extends = "⍄",
  precedes = "⍃",
  nbsp = "∙",
}
vim.opt.backspace = { "indent", "eol", "start" }

vim.opt.fixendofline = true -- <EOL> at the end of file will be restored if missing
vim.opt.formatoptions:append("j") -- Delete comment character when joining commented lines
vim.opt.formatoptions:append("m") -- Also break at a multibyte character above 255
vim.opt.formatoptions:append("B") -- When joining lines, don't insert a space between two multibyte characters
vim.opt.formatoptions:append("c") -- Auto-wrap comments using 'textwidth', inserting the current comment leader automatically.
vim.opt.formatoptions:append("r") -- Automatically insert the current comment leader after hitting <Enter> in Insert mode.
vim.opt.formatoptions:append("o") -- Automatically insert the current comment leader after hitting 'o' or 'O'
vim.opt.formatoptions:append("q") -- Allow formatting of comments with "gq"
vim.opt.formatoptions:append("l") -- Long lines are not broken in insert mode: When a line was longer than 'textwidth' when the insert command started, Vim does not automatically format it.
vim.opt.formatoptions:append("1") -- Don't break a line after a one-letter word

--- Local rc(.nvim.lua, .nvimrc, .exrc)を読む
vim.opt.exrc = true

--- よく間違えるmapを消す
vim.keymap.set("n", "Q", "<nop>", { remap = false, desc = "nop" })
vim.keymap.set("n", "gQ", "<nop>", { remap = false, desc = "nop" })

--- クォーテーションを含むTextobjにスペースを含めない
vim.keymap.set({ "o", "x" }, [[a']], [[2i']], { remap = false })
vim.keymap.set({ "o", "x" }, [[a"]], [[2i"]], { remap = false })
vim.keymap.set({ "o", "x" }, [[a`]], [[2i`]], { remap = false })

--- Quickfixの表示
vim.keymap.set("n", "<leader>qo", "<cmd>copen<cr><esc>", { remap = false, desc = "open a window to show the current list of errors" })
