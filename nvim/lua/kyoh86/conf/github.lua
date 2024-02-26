vim.keymap.set("n", "<leader>ghi", function()
  require("kyoh86.lib.volatile_terminal").split(0, {}, {
    exec = "gh issue new",
  })
end, { remap = false, desc = "Create new issue in the current repository on GitHub" })
vim.keymap.set("n", "<leader>ghp", function()
  require("kyoh86.lib.volatile_terminal").split(0, {}, {
    exec = "gh pr new",
  })
end, { remap = false, desc = "Create new pull-request in the current repository on GitHub" })
