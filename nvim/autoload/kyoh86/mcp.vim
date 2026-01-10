function! kyoh86#mcp#diagnostics(bufnr, severity) abort
  if !has('nvim')
    return []
  endif
  return luaeval(
    \ "require('kyoh86.lib.mcp').diagnostics(_A[1], _A[2])",
    \ [a:bufnr, a:severity],
    \ )
endfunction
