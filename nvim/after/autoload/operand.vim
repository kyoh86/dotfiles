function! operand#get(motion)
  " Get operand text and cursor positions for the |:map-operator| function
  let [l:bufnr, l:lnum1, l:col1] = getpos("'[")[0:2]
  let [l:lnum2, l:col2] = getpos("']")[1:2]
  if l:lnum1 == 0 && l:lnum2 == 0 && l:col1 == 0 && l:col2 == 0
    " There's no selection text
    return v:null
  endif
  " Get text lines in the operand
  let l:lines = getline(l:lnum1, l:lnum2)
  let [l:intro, l:outro] = ['', '']
  if a:motion ==# 'char'
    " Trim intro/outro text from the lines.
    let tail = l:col2 - (&selection == 'inclusive' ? 1 : 2)
    let head = l:col1 - 1
    let lnum = l:lnum2-l:lnum1
    let l:outro = l:lines[lnum][tail+1:]
    if head > 0
      let l:intro = l:lines[0][:head-1]
    endif
    let l:lines[lnum] = l:lines[lnum][:tail]
    let l:lines[0] = l:lines[0][head:]
  endif
  return copy(l:) " Return bufnr, lnum1, col1, lnum2, col2, lines, intro, outro
endfunction
