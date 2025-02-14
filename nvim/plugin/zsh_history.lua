-- .zsh_historyのバッファは、読み込み時にunmetafyして、保存時にmetafyする
-- .zsh_historyファイルを開いたときの設定
vim.api.nvim_create_autocmd("BufReadCmd", {
  pattern = ".zsh_history",
  callback = function()
    vim.bo.buftype = "acwrite"
    vim.bo.filetype = "zsh_history.zsh"
    require("kyoh86.conf.zsh_history").read_zsh_history()
  end,
})

-- .zsh_historyファイルを保存するときの設定
vim.api.nvim_create_autocmd("BufWriteCmd", {
  pattern = ".zsh_history",
  callback = function()
    require("kyoh86.conf.zsh_history").write_zsh_history()
  end,
})
