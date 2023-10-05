vim.api.nvim_buf_create_user_command(vim.fn.bufnr("%") --[[@as integer]], "YankTerraformAddress", function()
  local line = vim.fn.getline(".") --[[@as string]]
  local words = vim.fn.split(line, [[ \+]], false)
  local prefix = ""
  if #words < 4 or words[4] ~= "{" then
    return
  end
  if words[1] == "data" then
    prefix = "data."
  end
  if words[1] ~= "resource" then
    return
  end
  local kind = vim.fn.trim(words[2], '"')
  local name = vim.fn.trim(words[3], '"')
  if #kind == 0 or #name == 0 then
    return
  end
  vim.fn.setreg("*", prefix .. kind .. "." .. name)
end, { force = true })
