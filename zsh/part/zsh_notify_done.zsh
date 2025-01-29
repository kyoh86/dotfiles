# コマンドの終了をNeovim側に通知する
#
# 環境変数の設定: ../../nvim/lua/kyoh86/conf/envar.lua
# autocmdを受けてHeirlineの更新をしてる: ../../nvim/lua/kyoh86/plug/heirline/git.lua
# autocmdを受けて処理の終了を通知してる: ../../nvim/lua/kyoh86/conf/zsh-result.lua
if [ -n "${NVIM_SERVER_NAME}" ] ; then
  function _notify_precmd_to_nvim() {
    nvim --server ${NVIM_SERVER_NAME} --headless --remote-send "<cmd>doautocmd User Kyoh86TermNotifReceived:precmd:$?:$KYOH86_VOLATERM_BUFNR:$(echo $history[$(($HISTCMD-1))] | base64)<cr>"
  }
  add-zsh-hook precmd _notify_precmd_to_nvim
fi
