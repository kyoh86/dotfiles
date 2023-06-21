--- コマンドラインのKeymapをカスタマイズ
vim.keymap.set("c", "<C-A>", "<Home>", { remap = false, desc = "cursor to beginning of command-line" })
vim.keymap.set("c", "<C-F>", "<Right>", { remap = false, desc = "cursor right" })
vim.keymap.set("c", "<C-B>", "<Left>", { remap = false, desc = "cursor left" })
vim.keymap.set("c", "<C-D>", "<Del>", { remap = false, desc = "delete the character under the cursor (at end of line: character before the cursor)" })
vim.keymap.set("c", "<C-H>", "<BS>", { remap = false, desc = "delete the character in front of the cursor" })

-- Go back command histories with prefix in the command
vim.keymap.set("c", "<C-P>", "<Up>", { remap = false, desc = "recall older command-line from history, whose beginning matches the current command-line (see below)" })
vim.keymap.set("c", "<C-N>", "<Down>", { remap = false, desc = "recall more recent command-line from history, whose beginning matches the current command-line (see below)" })

-- enter command-line-window
vim.opt.cedit = vim.api.nvim_replace_termcodes("<c-y>", true, true, true)
