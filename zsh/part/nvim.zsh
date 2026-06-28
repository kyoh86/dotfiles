function _start_nvim {
  if [[ ! -o interactive ]]; then
    return
  fi
  if [[ -z "${TMUX}" ]]; then
    # tmuxの外では何もしない
    return
  fi
  if [[ -z "${NVIM_SERVER_NAME}" ]]; then
    # Neovim未起動なので起動する
    nvim && exit
    return
  fi

  # Neovimサーバーのソケットが生き残ってる限りは特に何もしない
  if [[ -S "$NVIM_SERVER_NAME" ]]; then
      return
  fi

  # サーバーソケット消えてる＝終了してると思われるのでNeovimを起動する
  nvim && exit
}

_start_nvim
