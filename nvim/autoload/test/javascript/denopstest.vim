" Returns true if the given file belongs to your test runner
function! test#javascript#denopstest#test_file(file) abort
  if a:file !~# '\v[\._]test\.(js|mjs|ts|jsx|tsx)$'
    return v:false
  endif

  return filereadable('deno.json') || filereadable('deno.jsonc')
endfunction

" Returns test runner's arguments which will run the current file and/or line
function! test#javascript#denopstest#build_position(type, position) abort
  if a:type ==# 'nearest'
    let name = s:nearest_test(a:position)
    if !empty(name)
      let name = shellescape(name, 1)
    endif
    return ['--filter', name, a:position['file']]
  elseif a:type ==# 'file'
    return [a:position['file']]
  else
    return []
  endif
endfunction

" Returns processed args (if you need to do any processing)
function! test#javascript#denopstest#build_args(args) abort
  return a:args
endfunction

" Returns the executable of your test runner
function! test#javascript#denopstest#executable() abort
  return 'deno test --allow-all'
endfunction
