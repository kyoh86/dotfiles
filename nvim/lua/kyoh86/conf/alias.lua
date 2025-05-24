-- To fix typos
-- The first argument "{mode}"; "ia", "ca" or "!a" for abbreviation in Insert mode, Cmdline mode, or both, respectively
-- See: "{mode}" in :help |nvim_set_keymap()|
vim.keymap.set({ "!a" }, "terraofrm", "terraform")
vim.keymap.set({ "!a" }, "terrafrom", "terraform")
vim.keymap.set({ "!a" }, "keyamp", "keymap")

-- CommandモードでTabキーを押したときに略語を展開
vim.api.nvim_set_keymap("c", "<Tab>", "v:lua.require('kyoh86.conf.alias').expand_cmd_abbrev()", { expr = true })

-- 略語を展開する汎用関数
local function expand_cmd_abbrev()
  local cmdline = vim.fn.getcmdline()
  local expand = vim.fn.maparg(cmdline, "c", true)

  -- 現在の入力が略語として登録されているか確認
  if expand ~= "" then
    -- 略語を展開
    return vim.api.nvim_replace_termcodes("<C-U>" .. expand, true, true, true)
  else
    -- 通常のTab動作
    return vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
  end
end

return {
  expand_cmd_abbrev = expand_cmd_abbrev,
}
