function denops#github#issue#view(owner, repo, num, opener)
  let l:opener = get(a:, "opener", {"reuse": v:true, "split": "none"})
  let l:reuse = get(l:opener, "reuse", v:true)
  let l:split = get(l:opener, "split", "none")
  let l:num = a:num
  if type(l:num) == v:t_number
    let l:num = string(a:num)
  endif
  call denops#notify("github", "router:open", ["issue/view", {"owner": a:owner, "repo": a:repo, "num": l:num}, "", l:opener])
endfunction

function denops#github#issue#edit(owner, repo, num, opener)
  let l:opener = get(a:, "opener", {"reuse": v:true, "split": "none"})
  let l:reuse = get(l:opener, "reuse", v:true)
  let l:split = get(l:opener, "split", "none")
  let l:num = a:num
  if type(l:num) == v:t_number
    let l:num = string(a:num)
  endif
  call denops#notify("github", "router:open", ["issue/edit", {"owner": a:owner, "repo": a:repo, "num": l:num}, "", l:opener])
endfunction
