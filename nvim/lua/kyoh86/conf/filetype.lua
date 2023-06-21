--- 一部の特殊なファイルについて、filetypeの割り当てを上書きする
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
