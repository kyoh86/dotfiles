autoload -Uz add-zsh-hook

typeset -g _NVIM_PROXY_IMPORTED_GUISE_PID=""

function nvim_proxy_import_env {
    _nvim_proxy_import_env "$@"
}

function _nvim_proxy_import_env {
    local exports
    exports="$(_nvim_proxy_env_exports "$@")" || return 1
    eval "$exports"
}

function _nvim_proxy_env_exports {
    local require_all=false
    if [[ "$1" == "--require-all" ]]; then
        require_all=true
        shift
    fi
    if (( $# == 0 )); then
        return 1
    fi
    if [ -z "$NVIM_PROXY_URL" ] || [ -z "$NVIM_PID" ]; then
        return 1
    fi
    if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    local name payload ret
    for name in "$@"; do
        case "$name" in
            ""|[0-9]*|*[!A-Za-z0-9_]* )
                return 1
                ;;
        esac
    done

    payload="$(printf '%s\n' "$@" | jq -R . | jq -s '{names: .}')"
    ret="$(
        curl -fsSL --max-time 1 \
            -H "X-Nvim-Pid: ${NVIM_PID}" \
            -H "content-type: application/json" \
            "${NVIM_PROXY_URL}/env" \
            -d "$payload" 2>/dev/null
    )" || return 1

    printf '%s' "$ret" | jq -er --argjson requested "$payload" --argjson require_all "$require_all" '
        (.env // {}) as $env
        | select(($require_all | not) or all($requested.names[]; ($env[.] // "") != ""))
        | $requested.names[] as $name
        | select($env[$name] != null)
        | "export \($name)=\($env[$name] | @sh)"
    ' 2>/dev/null
}

function _nvim_proxy_sync_guise_env {
    # A shell started inside Neovim already has the correct parent.
    if [[ -n "$GUISE_ADDRESS" && -z "$_NVIM_PROXY_IMPORTED_GUISE_PID" ]]; then
        [[ -z "$EDITOR" ]] || export REACT_EDITOR="$EDITOR"
        return
    fi
    if [[ -n "$GUISE_ADDRESS" && "$_NVIM_PROXY_IMPORTED_GUISE_PID" == "$NVIM_PID" ]]; then
        return
    fi

    _nvim_proxy_import_env --require-all GUISE_ADDRESS EDITOR VISUAL || return 0
    export REACT_EDITOR="$EDITOR"
    _NVIM_PROXY_IMPORTED_GUISE_PID="$NVIM_PID"
}

add-zsh-hook precmd _nvim_proxy_sync_guise_env
_nvim_proxy_sync_guise_env
