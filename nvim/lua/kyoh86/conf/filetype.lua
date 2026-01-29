--- 一部の特殊なファイルについて、filetypeの割り当てを上書きする
local au = require("kyoh86.lib.autocmd")
au.group("kyoh86.conf.filetype", true):hook("BufReadPre", {
  once = true,
  callback = function()
    vim.filetype.add({
      extension = {
        jax = "help",
      },
      filename = {
        [".envrc"] = "sh",
        ["tsconfig.json"] = "jsonc",
      },
      pattern = {
        [".*/%.git/config"] = "gitconfig",
        [".*/%.git/.*%.conf"] = "gitconfig",
        [".*/git/config"] = "gitconfig",
        [".*/git/.*%.conf"] = "gitconfig",

        [".*/%.ssh/.*%.conf"] = "sshconfig",
        [".*/ssh/.*%.conf"] = "sshconfig",
      },
    })
  end,
})
