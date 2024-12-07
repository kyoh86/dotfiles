let s:CANCEL_RETURN = "kyoh86.ddu.source.github.input.cancel_return"

function kyoh86#ddu#source#github#input#cancel(prompt, text, completion)
  let l:ret = input({
        \ "prompt": a:prompt,
        \ "default": a:text,
        \ "completion": a:completion,
        \ "cancelreturn": s:CANCEL_RETURN,
        \ })
  if l:ret ==# s:CANCEL_RETURN
    return "is:open "
  endif
  return l:ret
endfunction
