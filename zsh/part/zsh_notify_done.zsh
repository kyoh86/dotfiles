# コマンドの終了をNeovim側に通知する
#
# ref(プロキシサーバー): ../../nvim/denops/term-notif/main.ts
# ref(通知送信スクリプト) ../../nvim/denops/term-notif/notify.ts
if [ -n "${KYOH86_TERM_NOTIFY_ADDRESS}" ] && [ -n "${KYOH86_TERM_NOTIFY_COMMAND}" ]; then
  function _notify_precmd_to_nvim() {
    ${KYOH86_TERM_NOTIFY_COMMAND} "precmd:$?:$KYOH86_VOLATERM_BUFNR"
  }
  add-zsh-hook precmd _notify_precmd_to_nvim
fi
