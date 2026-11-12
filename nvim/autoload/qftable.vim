function! qftable#show(opts) abort
  call luaeval("require('kyoh86.lib.qftable').show(_A)", a:opts)
endfunction
