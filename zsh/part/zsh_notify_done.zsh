# コマンドの終了をNeovim側に通知する
#
# ref(プロキシサーバー): ../../nvim/denops/zsh-notif/main.ts
# ref(通知送信スクリプト) ../../nvim/denops/zsh-notif/notify.ts
if [ -n "${KYOH86_ZSH_NOTIFY_ADDRESS}" ] && [ -n "${KYOH86_ZSH_NOTIFY_COMMAND}" ]; then
  function _notify_precmd_to_nvim() {
    ${KYOH86_ZSH_NOTIFY_COMMAND} "precmd"
  }
  add-zsh-hook precmd _notify_precmd_to_nvim
fi
