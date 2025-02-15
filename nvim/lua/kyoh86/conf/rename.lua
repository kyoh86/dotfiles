--- 現在のファイルの移動
local function rename(e)
  local newname = e.fargs[1]
  local oldname = vim.api.nvim_buf_get_name(0)
  if vim.uv.fs_realpath(newname) == vim.uv.fs_realpath(oldname) then
    return
  end
  vim.cmd("saveas" .. (e.bang and "! " or " ") .. "++p" .. newname)
  vim.fn.delete(oldname)
  vim.cmd.bdelete(oldname)
  vim.cmd({ cmd = "edit", mods = { silent = true } })
end

local opt = {
  force = true,
  bang = true,
  bar = true,
  complete = "file",
  nargs = 1,
}
vim.api.nvim_create_user_command("Move", rename, opt)
vim.api.nvim_create_user_command("Rename", rename, opt)
vim.api.nvim_create_user_command("SaveAs", [[echoerr "SaveAs is moved to :Move or :Rename. If you want to COPY the buffer to another file, use :saveas"]], opt)
