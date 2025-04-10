--- SHELLをzshに設定する
---@param shells string[]  Shell path candidates
local function attempt_set_shell(shells)
  for _, shell in ipairs(shells) do
    if vim.fn.filereadable(shell) == 1 then
      vim.o.shell = shell
      vim.env.SHELL = shell
      return true
    end
  end
  return false
end

attempt_set_shell({ vim.env.HOME .. "/.nix-profile/bin/zsh", "/usr/local/bin/zsh", "/usr/bin/zsh", "/bin/zsh" })

--- Terminal内で環境がNvim内であることを示す変数を設定しておく
vim.env.NVIM_TERMINAL = 1
