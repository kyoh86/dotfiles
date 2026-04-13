function claude-last() {
  local claude_config_dir history_file last_session_id target_pwd line session_cwd session_id
  claude_config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.config/claude}"
  history_file="${claude_config_dir}/history.jsonl"
  target_pwd="$(pwd -P)"

  if [ -f "${history_file}" ]; then
    while IFS= read -r line; do
      session_cwd="$(printf '%s\n' "${line}" | sed -n 's/.*"project":"\([^"]*\)".*/\1/p')"
      session_id="$(printf '%s\n' "${line}" | sed -n 's/.*"sessionId":"\([^"]*\)".*/\1/p')"
      if [ -n "${session_id}" ] && [ -n "${session_cwd}" ]; then
        if [[ "${target_pwd}" == "${session_cwd}" || "${target_pwd}" == "${session_cwd}"/* ]]; then
          last_session_id="${session_id}"
        fi
      fi
    done < "${history_file}"
  fi

  if [ -n "${last_session_id}" ]; then
    claude -r "${last_session_id}"
    return 0
  fi

  echo "claude session id not found for ${target_pwd}" >&2
  return 1
}
