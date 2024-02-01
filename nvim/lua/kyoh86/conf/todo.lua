vim.keymap.set("n", "<leader>tit", [[<cmd>Ripgrep -i to]] .. [[do<cr>]], { remap = false, desc = "To" .. "Doを検索する" })
vim.keymap.set("n", "<leader><leader>t", [[<cmd>new ~/.local/state/to]] .. [[do.md<cr>]], { remap = false, desc = "作業メモを編集する" })
