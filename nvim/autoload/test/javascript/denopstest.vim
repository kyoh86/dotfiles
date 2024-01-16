" Returns true if the given file belongs to your test runner
function! test#javascript#denopstest#test_file(file) abort
  if a:file !~# '\v[\._]test\.(js|mjs|ts|jsx|tsx)$'
    return v:false
  endif

  return (filereadable('deno.json') || filereadable('deno.jsonc') && isdorectory('denops'))
endfunction

" Returns test runner's arguments which will run the current file and/or line
function! test#javascript#denopstest#build_position(type, position) abort
  if a:type ==# 'nearest'
    let l:name = s:nearest_test(a:position)
    if !empty(l:name)
      let l:name = shellescape(l:name, 1)
    endif
    return ['--filter', l:name]
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

function! s:nearest_test(position) abort
  let l:patterns = {
    \ 'test': ['\v^\s*(test)\s*('],
    \ 'namespace': g:test#javascript#patterns['namespace'],
    \}

  let l:name = test#base#nearest_test(a:position, l:patterns)

  " If we didn't find the 'test', return empty
  if empty(name['test']) || 'test' != name['test'][0]
    return ''
  endif

  " TODO: Check test("name", ...) pattern
  " TODO: Check test(\n"name", ...) pattern
  " Check test({\nname:"name", ...) pattern
  let name = test#base#nearest_test_in_lines(
    \ a:position['file'],
    \ name['test_line'],
    \ a:position['line'],
    \ '\v^\s*name:\s*["''](.*)["'']',
  \ )

  " TODO: Check test({\nname:\n"name", ...) pattern

  return join(name['test'])
endfunction
