--- 検索と置換

--- 検索・置換周りの設定
vim.opt.inccommand = "split"
vim.opt.incsearch = true
vim.opt.grepprg = "rg --vimgrep --no-heading"
vim.opt.grepformat = "%f:%l:%c:%m,%f:%l:%m"

--- 検索結果ハイライトの消去
vim.keymap.set("n", "<C-l>", "<cmd>nohlsearch<cr><C-l>", {
  desc = "Clear highlighting of the searched words (nohlsearch)",
})

--- 検索と置換を切り替える
local range_store = {}

local function get_stored_range()
  if #range_store > 0 then
    local range = range_store[1]
    range_store = {}
    return range
  else
    return "%"
  end
end

local toggle_cmdtype = vim.keycode("<End><C-U><BS>")

local function switch_search_replace()
  local cmdtype = vim.fn.getcmdtype()
  if cmdtype == "/" or cmdtype == "?" then
    local range = get_stored_range()
    return toggle_cmdtype .. vim.fn.substitute(vim.fn.getcmdline(), [[^\(.*\)]], ":" .. range .. [[s/\1]], "")
  elseif cmdtype == ":" then
    local list = vim.fn.matchlist(vim.fn.getcmdline(), [[^\(.*\)s\%[ubstitute]\/\(.*\)$]])
    local range = list[2]
    local expr = list[3]
    range_store[1] = range

    if range == [['<,'>]] then
      vim.fn.setpos(".", vim.fn.getpos("'<"))
    end
    return toggle_cmdtype .. "/" .. expr
  end
end

vim.keymap.set("c", [[<C-\><c-o>]], switch_search_replace, { expr = true, remap = false })
