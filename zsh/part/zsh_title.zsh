function _window_title_cmd () {
  local pwd="${PWD/~HOME/~}"
  print -n "\e]0;"
  print -n "${pwd##*/}"
  print -n "\a"
}

function _window_title_exec () {
  local pwd="${PWD/~HOME/~}"
  print -n "\e]0;"
  print -n "${pwd##*/}:${1:0:32}"
  print -n "\a"
}

[[ "$TERM" =~ "^xterm" ]] && {
  add-zsh-hook precmd _window_title_cmd
  add-zsh-hook preexec _window_title_exec
}
