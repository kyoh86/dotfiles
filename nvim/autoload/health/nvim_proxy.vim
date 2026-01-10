function! health#nvim_proxy#check() abort
  if exists('*luaeval')
    call luaeval('require("health.nvim_proxy").check()')
    return
  endif
  call health#report_start('nvim-proxy')
  call health#report_warn('luaeval is not available')
endfunction
