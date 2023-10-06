--- ターミナル関係の設定

vim.o.termguicolors = true

vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("kyoh86-conf-terminal", {}),
  pattern = "term://*",
  callback = function()
    -- 行番号を表示しない
    vim.opt_local.number = false
    vim.opt_local.scrollback = 100000
    vim.opt_local.relativenumber = false
    local buf = vim.api.nvim_get_current_buf()
    -- ノーマルモード、ヴィジュアルモードの<Up>で一つ前のプロンプトに戻る
    vim.keymap.set({ "n", "v" }, "<up>", [[<cmd>call search('^\(\$\( \|$\)\)\@=', 'bW')<cr>]], { remap = false, buffer = buf, silent = true, desc = "search previous prompt" })
    -- ノーマルモード、ヴィジュアルモードの<Down>で一つ後のプロンプトに戻る
    vim.keymap.set({ "n", "v" }, "<down>", [[<cmd>call search('^\(\$\( \|$\)\)\@=', 'W')<cr>]], { remap = false, buffer = buf, silent = true, desc = "search next prompt" })
  end,
})
