function codex_resume_last() {
  local codex_home history_file sessions_dir last_session_id target_pwd file line session_cwd
  codex_home="${CODEX_HOME:-$HOME/.codex}"
  sessions_dir="${codex_home}/sessions"
  history_file="${codex_home}/history.jsonl"
  target_pwd="$(pwd -P)"

  if [ -d "${sessions_dir}" ]; then
    local session_files
    session_files=(${(f)"$(command find "${sessions_dir}" -type f -name '*.jsonl' -print 2>/dev/null | sort -r)"})
    for file in "${session_files[@]}"; do
      line="$(head -n 1 "${file}")"
      session_cwd="$(printf '%s\n' "${line}" | sed -n 's/.*"cwd":"\([^"]*\)".*/\1/p')"
      last_session_id="$(printf '%s\n' "${line}" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')"
      if [ -n "${last_session_id}" ] && [ -n "${session_cwd}" ]; then
        if [[ "${target_pwd}" == "${session_cwd}" || "${target_pwd}" == "${session_cwd}"/* ]]; then
          echo "codex resume ${last_session_id}"
          return 0
        fi
      fi
    done
  fi

  if [ -f "${history_file}" ]; then
    last_session_id="$(
      tail -n 1 "${history_file}" |
        sed -n 's/.*"session_id":"\([^"]*\)".*/\1/p'
    )"
    if [ -n "${last_session_id}" ]; then
      echo "codex resume ${last_session_id}"
      return 0
    fi
  fi

  echo "codex session id not found for ${target_pwd}" >&2
  return 1

}

function codex_resume_last_run() {
  local cmd
  cmd="$(codex_resume_last)" || return
  BUFFER="${cmd}"
  zle accept-line
  zle -R -c
}
zle -N codex_resume_last_run
bindkey '^xcr' codex_resume_last_run
bindkey '^xc^r' codex_resume_last_run
bindkey '^x^cr' codex_resume_last_run
bindkey '^x^c^r' codex_resume_last_run
