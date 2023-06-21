vim.g["test#strategy"] = "neovim"
vim.g["test#neovim#term_position"] = "aboveleft"
vim.g["test#neovim#start_normal"] = 1
vim.g["test#preserve_screen"] = 1
vim.g["test#echo_command"] = true
vim.g["test#lua#busted#executable"] = "vusted"

---@type LazySpec
local spec = {
  "vim-test/vim-test",
  dependencies = { "tpope/vim-dispatch" },
  cmd = {
    "TestVisit",
    "TestNearest",
    "TestNearest",
    "TestFile",
    "TestSuite",
    "TestLast",
  },
  keys = {
    { "<leader>tg", "<cmd>TestVisit<cr>", silent = true, remap = false, desc = "open the last run test in the current buffer" },
    { "<leader>tt", "<cmd>TestNearest<cr>", silent = true, remap = false, desc = "run a test nearest to the cursor (some test runners may not support this)" },
    { "<leader>tn", "<cmd>TestNearest<cr>", silent = true, remap = false, desc = "run a test nearest to the cursor (some test runners may not support this)" },
    { "<leader>tf", "<cmd>TestFile<cr>", silent = true, remap = false, desc = "run tests for the current file" },
    { "<leader>ta", "<cmd>TestSuite<cr>", silent = true, remap = false, desc = "run test suite of the current file" },
    { "<leader>tl", "<cmd>TestLast<cr>", silent = true, remap = false, desc = "run the last test" },
  },
}
return spec
