#!/bin/sh

autoload -Uz add-zsh-hook
autoload -Uz colors
colors

function _denops_precommit_status_print {
  if [ -z "$PRECOMMIT_ADDRESS" ]; then
    return
  fi

  local payload ret total truncated
  payload="$(jq -n --arg dir "$PWD" --argjson limit 10 '{dir:$dir, mode:"status", limit:$limit}')"
  ret="$(curl -XPOST -sSL --max-time 2 "$PRECOMMIT_ADDRESS" -d "$payload" 2>/dev/null)"
  if [ -z "$ret" ]; then
    return
  fi

  total="$(printf '%s' "$ret" | jq -r '.total // empty' 2>/dev/null)"
  if [ -n "$total" ] && [ "$total" -gt 0 ] 2>/dev/null; then
    print -P -- "%F{yellow}==============================%f"
    print -P -- "%F{red}Unsaved buffers (cwd): $total%f"
    print -r -- "$ret" | jq -r '.files[]' 2>/dev/null | sed 's/^/  - /'
    truncated="$(printf '%s' "$ret" | jq -r '.truncated // false' 2>/dev/null)"
    if [ "$truncated" = "true" ]; then
      print -r -- "  ... (more)"
    fi
    print -P -- "%F{yellow}==============================%f"
    print -r -- ""
  fi
}

function _denops_precommit_preexec {
  local cmd="$1"
  if [[ "$cmd" == git\ status* ]] || [[ "$cmd" == git\ -C\ *\ status* ]]; then
    _denops_precommit_status_print
  fi
}

add-zsh-hook preexec _denops_precommit_preexec
