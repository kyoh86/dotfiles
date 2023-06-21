--- SHELLをzshに設定する
local function attempt_set_shell(shell)
  if vim.fn.filereadable(shell) == 1 then
    vim.o.shell = shell
    vim.env.SHELL = shell
  end
end

attempt_set_shell("/usr/local/bin/zsh")
attempt_set_shell("/usr/bin/zsh")
attempt_set_shell("/bin/zsh")

--- Terminal内で環境がNvim内であることを示す変数を設定しておく
vim.env.NVIM_TERMINAL = 1
