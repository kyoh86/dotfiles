# コマンドの終了をNeovim側に通知する
#
# 環境変数の設定: nvim-proxy
# autocmdを受けてHeirlineの更新をしてる: ../../nvim/lua/kyoh86/plug/heirline/git.lua
# autocmdを受けて処理の終了を通知してる: ../../nvim/lua/kyoh86/conf/zsh-result.lua
if [ -n "${NVIM_PROXY_URL}" ] && [ -n "${NVIM_PID}" ] ; then
  function _notify_precmd_to_nvim() {
    local command event payload
    command="$(printf '%s' "$history[$(($HISTCMD-1))]" | base64 -w 0 | tr '+/' '-_' | tr -d '=')"
    event="Kyoh86TermNotifReceived:precmd:$?::$command"
    payload="$(jq -n --arg event "$event" '{event:$event}')"
    curl -XPOST -sSL --max-time 1 \
      -H "X-Nvim-Pid: ${NVIM_PID}" \
      -H "content-type: application/json" \
      "${NVIM_PROXY_URL}/notify" \
      -d "$payload" >/dev/null 2>&1
  }
  add-zsh-hook precmd _notify_precmd_to_nvim
fi
