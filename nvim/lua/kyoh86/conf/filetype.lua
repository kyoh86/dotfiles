--- 一部の特殊なファイルについて、filetypeの割り当てを上書きする
vim.api.nvim_create_autocmd("BufReadPre", {
  group = vim.api.nvim_create_augroup("kyoh86-conf-filetype", {}),
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
