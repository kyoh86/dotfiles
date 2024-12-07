vim.keymap.set("n", "<leader>j9", "[(", { desc = "マッチしない開き括弧に移動する" })
vim.keymap.set("n", "<leader>j0", "])", { desc = "マッチしない閉じ括弧に移動する" })

vim.keymap.set("n", "<leader>jcN", "<cmd>cnfile<cr>", { desc = "Quickfixの次のファイルに移動する" })
vim.keymap.set("n", "<leader>jcn", "<cmd>cnext<cr>", { desc = "Quickfixの次の場所に移動する" })
vim.keymap.set("n", "<leader>jcp", "<cmd>cprevious<cr>", { desc = "Quickfixの前の場所に移動する" })
vim.keymap.set("n", "<leader>jcP", "<cmd>cpfile<cr>", { desc = "Quickfixの前のファイルに移動する" })

vim.keymap.set("n", "<leader>jlN", "<cmd>lnfile<cr>", { desc = "Locationの次のファイルに移動する" })
vim.keymap.set("n", "<leader>jln", "<cmd>lnext<cr>", { desc = "Locationの次の場所に移動する" })
vim.keymap.set("n", "<leader>jlp", "<cmd>lprevious<cr>", { desc = "Locationの前の場所に移動する" })
vim.keymap.set("n", "<leader>jlP", "<cmd>lpfile<cr>", { desc = "Locationの前のファイルに移動する" })

vim.keymap.set("n", "<leader>jbn", "<cmd>bnext<cr>", { desc = "次のバッファに移動する" })
vim.keymap.set("n", "<leader>jbp", "<cmd>bprevious<cr>", { desc = "前のバッファに移動する" })
vim.keymap.set("n", "<leader>jan", "<cmd>next<cr>", { desc = "次の引数に移動する" })
vim.keymap.set("n", "<leader>jap", "<cmd>previous<cr>", { desc = "前の引数に移動する" })
