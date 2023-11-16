" ref: ../lua/kyoh86/conf/todo.lua

function! TodoCommandCompletion(...)
  return [ 'new', 'note', 'sync' ]
endfunction

command! -nargs=? -complete=customlist,TodoCommandCompletion Todo call v:lua.handle_todo_command(<f-args>)

function! GetTodoList()
  return luaeval('require"kyoh86.conf.todo".load_task_list()')
endfunction

