# コマンド履歴の設定
HISTFILE=${HOME}/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

setopt extended_history       # 補完時にヒストリを自動的に展開
setopt hist_ignore_all_dups   # ヒストリに追加されるコマンド行が古いものと同じなら古いものを削除
setopt hist_ignore_space      # スペースで始まるコマンド行はヒストリリストから削除
setopt hist_reduce_blanks     # 余分な空白は詰めて記録
setopt hist_no_store          # historyコマンドは履歴に登録しない
setopt hist_verify            # ヒストリを呼び出してから実行する間に一旦編集可能

# historyファイルに残さない
HISTORY_IGNORE="(cat|cd|export|gh|git|t)"

# セッション中の履歴にも残さない
typeset -ga HISTORY_IGNORE_COMMANDS=(
  chmod
  chown
  cp
  exit
  gi
  ln
  ls
  mv
  rm
  rmdir
  t
)

zshaddhistory() {
  emulate -L zsh

  local entry=${1%$'\n'}
  local command=${entry%%$'\n'*}
  local ignored

  [[ ${entry} == *$'\n'* ]] && return 1

  for ignored in "${HISTORY_IGNORE_COMMANDS[@]}"; do
    case "${command}" in
      "${ignored}"|"${ignored} "*) return 1 ;;
    esac
  done

  return 0
}

function _zsh_history_ddu() {
  emulate -L zsh

  if [[ -z "${TMUX}" || -z "${TMUX_PANE}" ]]; then
    zle reset-prompt
    return 0
  fi
  if [[ -z "${NVIM_SERVER_NAME}" || ! -S "${NVIM_SERVER_NAME}" ]]; then
    zle reset-prompt
    return 0
  fi

  nvim --server "${NVIM_SERVER_NAME}" --remote-expr \
    "luaeval('require(\"kyoh86.lib.zsh_history_ddu\").start_tmux(_A)', '${TMUX_PANE}')" \
    >/dev/null 2>&1
  zle reset-prompt
}

zle -N zsh-history-ddu _zsh_history_ddu
bindkey -M emacs '^x^r' zsh-history-ddu
bindkey -M emacs '^xr' zsh-history-ddu
