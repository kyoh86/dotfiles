--- <C-w>で使えるウィンドウの管理系をターミナルモードにマップする
vim.keymap.set("t", "<C-W>n", "<cmd>new<cr>", { remap = true, desc = "create a new window and start editing an empty file in it" })
vim.keymap.set("t", "<C-W><C-N>", "<cmd>new<cr>", { remap = true, desc = "create a new window and start editing an empty file in it" })
vim.keymap.set("t", "<C-W>q", "<cmd>quit<cr>", { remap = true, desc = "quit the current window" })
vim.keymap.set("t", "<C-W><C-Q>", "<cmd>quit<cr>", { remap = true, desc = "quit the current window" })
vim.keymap.set("t", "<C-W>c", "<cmd>close<cr>", { remap = true, desc = "close the current window" })
vim.keymap.set("t", "<C-W>o", "<cmd>only<cr>", { remap = true })
vim.keymap.set("t", "<C-W><C-O>", "<cmd>only<cr>", { remap = true, desc = "make the current window the only one on the screen" })
vim.keymap.set("t", "<C-W><Down>", "<cmd>wincmd j<cr>", { remap = true, desc = "move cursor to below window" })
vim.keymap.set("t", "<C-W><C-J>", "<cmd>wincmd j<cr>", { remap = true, desc = "move cursor to below window" })
vim.keymap.set("t", "<C-W>j", "<cmd>wincmd j<cr>", { remap = true, desc = "move cursor to below window" })
vim.keymap.set("t", "<C-W><Up>", "<cmd>wincmd k<cr>", { remap = true, desc = "move cursor to above window" })
vim.keymap.set("t", "<C-W><C-K>", "<cmd>wincmd k<cr>", { remap = true, desc = "move cursor to above window" })
vim.keymap.set("t", "<C-W>k", "<cmd>wincmd k<cr>", { remap = true, desc = "move cursor to above window" })
vim.keymap.set("t", "<C-W><Left>", "<cmd>wincmd h<cr>", { remap = true, desc = "move cursor to left window" })
vim.keymap.set("t", "<C-W><C-H>", "<cmd>wincmd h<cr>", { remap = true, desc = "move cursor to left window" })
vim.keymap.set("t", "<C-W><BS>", "<cmd>wincmd h<cr>", { remap = true, desc = "move cursor to left window" })
vim.keymap.set("t", "<C-W>h", "<cmd>wincmd h<cr>", { remap = true, desc = "move cursor to left window" })
vim.keymap.set("t", "<C-W><Right>", "<cmd>wincmd l<cr>", { remap = true, desc = "move cursor to right window" })
vim.keymap.set("t", "<C-W><C-L>", "<cmd>wincmd l<cr>", { remap = true, desc = "move cursor to right window" })
vim.keymap.set("t", "<C-W>l", "<cmd>wincmd l<cr>", { remap = true, desc = "move cursor to right window" })
vim.keymap.set("t", "<C-W>w", "<cmd>wincmd w<cr>", { remap = true, desc = "move cursor to window below/right of the current one" })
vim.keymap.set("t", "<C-W><C-W>", "<cmd>wincmd w<cr>", { remap = true, desc = "move cursor to window below/right of the current one" })
vim.keymap.set("t", "<C-W>W", "<cmd>wincmd W<cr>", { remap = true, desc = "move cursor to window above/left of the current one" })
vim.keymap.set("t", "<C-W>t", "<cmd>wincmd t<cr>", { remap = true, desc = "move the current window to a new tab page" })
vim.keymap.set("t", "<C-W><C-T>", "<cmd>wincmd t<cr>", { remap = true, desc = "move the current window to a new tab page" })
vim.keymap.set("t", "<C-W>b", "<cmd>wincmd b<cr>", { remap = true, desc = "move cursor to bottom-right window" })
vim.keymap.set("t", "<C-W><C-B>", "<cmd>wincmd b<cr>", { remap = true, desc = "move cursor to bottom-right window" })
vim.keymap.set("t", "<C-W>p", "<cmd>wincmd p<cr>", { remap = true, desc = "go to previous (last accessed) window" })
vim.keymap.set("t", "<C-W><C-P>", "<cmd>wincmd p<cr>", { remap = true, desc = "go to previous (last accessed) window" })
vim.keymap.set("t", "<C-W>P", "<cmd>wincmd P<cr>", { remap = true, desc = "go to preview window.  When there is no preview window this is an error" })
vim.keymap.set("t", "<C-W>r", "<cmd>wincmd r<cr>", { remap = true, desc = "rotate windows downwards/rightwards" })
vim.keymap.set("t", "<C-W><C-R>", "<cmd>wincmd r<cr>", { remap = true, desc = "rotate windows downwards/rightwards" })
vim.keymap.set("t", "<C-W>R", "<cmd>wincmd R<cr>", { remap = true, desc = "rotate windows downwards/rightwards" })
vim.keymap.set("t", "<C-W>x", "<cmd>wincmd x<cr>", { remap = true, desc = "exchange current window with next one" })
vim.keymap.set("t", "<C-W><C-X>", "<cmd>wincmd x<cr>", { remap = true, desc = "exchange current window with next one" })
vim.keymap.set("t", "<C-W>K", "<cmd>wincmd K<cr>", { remap = true, desc = "move the current window to be at the very top, using the full width of the screen" })
vim.keymap.set("t", "<C-W>J", "<cmd>wincmd J<cr>", { remap = true, desc = "move the current window to be at the very bottom, using the full width of the screen" })
vim.keymap.set("t", "<C-W>H", "<cmd>wincmd H<cr>", { remap = true, desc = "move the current window to be at the far left, using the full height of the screen" })
vim.keymap.set("t", "<C-W>L", "<cmd>wincmd L<cr>", { remap = true, desc = "move the current window to be at the far right, using the full height of the screen" })
vim.keymap.set("t", "<C-W>T", "<cmd>wincmd T<cr>", { remap = true, desc = "move the current window to a new tab page" })
vim.keymap.set("t", "<C-W>=", "<cmd>wincmd =<cr>", { remap = true, desc = "make all windows (almost) equally high and wide, but use 'winheight' and 'winwidth' for the current window." })
vim.keymap.set("t", "<C-W>-", "<cmd>wincmd -<cr>", { remap = true, desc = "decrease current window height" })
vim.keymap.set("t", "<C-W>+", "<cmd>wincmd +<cr>", { remap = true, desc = "increase current window height" })
