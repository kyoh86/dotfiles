if exists("g:loaded_nvim_proxy")
  finish
endif
let g:loaded_nvim_proxy = 1

command! NvimProxyInstall call denops#notify("nvim-proxy", "install", [])
command! NvimProxyStart call denops#notify("nvim-proxy", "start", [])
command! NvimProxyEnsure call denops#notify("nvim-proxy", "ensure", [])
