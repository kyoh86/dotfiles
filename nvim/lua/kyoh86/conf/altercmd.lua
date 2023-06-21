local function create(original, alternative, cmdtype)
  if cmdtype == nil then
    cmdtype = ":"
  end
  local cmd = [[ cabbrev <expr> ]] .. original .. [[ (getcmdtype() ==# "]] .. cmdtype .. [[" && getcmdline() ==# "]] .. original .. [[") ? "]] .. alternative .. [[" : "]] .. original .. [[" ]]
  vim.cmd(cmd)
end

create("vh", "vertical help")
create("vhelp", "vertical help")
