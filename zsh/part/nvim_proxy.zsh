autoload -Uz add-zsh-hook

typeset -g _NVIM_PROXY_IMPORTED_GUISE_PID=""

function nvim_proxy_import_env {
    _nvim_proxy_import_env "$@"
}

function _nvim_proxy_import_env {
    if [ -z "$NVIM_PROXY_URL" ] || [ -z "$NVIM_PID" ]; then
        return 1
    fi
    if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    local name payload ret exports
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

    exports="$(
        printf '%s' "$ret" \
            | jq -r '.env // {} | to_entries[] | select(.value != null) | "export \(.key)=\(.value | @sh)"' 2>/dev/null
    )"
    if [ -z "$exports" ]; then
        return 1
    fi
    eval "$exports"
}

function _nvim_proxy_sync_guise_env {
    if [ -z "$NVIM_PROXY_URL" ] || [ -z "$NVIM_PID" ]; then
        return
    fi
    if [ "$_NVIM_PROXY_IMPORTED_GUISE_PID" = "$NVIM_PID" ] && [ -n "$GUISE_PROXY_ADDRESS" ]; then
        return
    fi

    _nvim_proxy_import_env GUISE_PROXY_ADDRESS EDITOR || return 0
    if [ -n "$GUISE_PROXY_ADDRESS" ]; then
        if [ -n "$EDITOR" ]; then
            export REACT_EDITOR="$EDITOR"
        fi
        _NVIM_PROXY_IMPORTED_GUISE_PID="$NVIM_PID"
    fi
}

add-zsh-hook precmd _nvim_proxy_sync_guise_env
_nvim_proxy_sync_guise_env
