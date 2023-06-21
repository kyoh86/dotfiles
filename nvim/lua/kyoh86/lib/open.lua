local function gui(target)
  if vim.loop.os_uname().sysname == "Darwin" then
    vim.fn.system("open " .. vim.fn.shellescape(target))
  elseif vim.fn.executable("wslview") == 1 then
    vim.fn.system("wslview " .. vim.fn.shellescape(target))
  elseif vim.fn.executable("xdg-open") == 1 then
    vim.fn.system("xdg-open " .. vim.fn.shellescape(target))
  else
    vim.notify("No executables to open file/url", vim.log.levels.ERROR)
  end
end

return {
  gui = gui,
}
