function nvim_env {
    local subcommand="$1"
    local target="$2"

    case "$target" in
        ?* )
            ;;
        * )
            echo "Invalid environment name: \"$target\""
            _nvim_env_usage
            return
            ;;
    esac

    case "$subcommand" in
        "init" )
            _nvim_env_init "$target"
            ;;
        "reset" )
            _nvim_env_reset "$target"
            ;;
        "delete"|"remove" )
            _nvim_env_delete "$target"
            ;;
        * )
            echo "Invalid subcommand: \"$subcommand\""
            _nvim_env_usage
            return
            ;;
    esac
}

function _nvim_env_usage {
    echo "USAGE: nvim_env <subcommand> <name>"
    echo ""
    echo "   Subcommands:"
    echo "      init <name>"
    echo "         Create boilerplate of the named env (nvim-<name>) for the Neovim"
    echo "         It will create dirs for the env, such as config, share, state and cache"
    echo ""
    echo "      reset <name>"
    echo "         Reset the named env (nvim-<name>) for the Neovim"
    echo "         It will remove dirs for the env, such as share, state and cache, except for config"
    echo ""
    echo "      delete <name>"
    echo "         Delete the named env (nvim-<name>) for the Neovim"
    echo "         It will remove all dirs for the env, such as share, state, cache and config"
    echo ""
    echo "   Arguments:"
    echo "      <name>"
    echo "         A name of the environment for the Neovim"
    echo "         It will used as 'nvim-<name>'"
    return 1
}

function _nvim_env_rmr {
    local dir="$1"
    if [ -d "$dir" ]; then
        read "go_ahead?Are you sure you delete \"$dir\"? [y/N] "
        if [[ "$go_ahead" = "y" ]]; then
            rm -rf "$dir"
            echo "Deleted dir: \"$dir\""
        else
            return 1
        fi
    fi
}

function _nvim_env_init {
    local target="$1"
    local dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim-$target"
    mkdir -p "$dir" \
    && echo "Created dir: \"$dir\"" \
    && touch "$dir/init.lua" \
    && echo "Created init.lua"
}

function _nvim_env_reset {
    local target="$1"
    _nvim_env_rmr "${XDG_DATA_HOME:-$HOME/.local/share}/nvim-$target" || return 1
    _nvim_env_rmr "${XDG_STATE_HOME:-$HOME/.local/state}/nvim-$target" || return 1
    _nvim_env_rmr "${XDG_CACHE_HOME:-$HOME/.cache}/nvim-$target" || return 1
}

function _nvim_env_delete {
    local target="$1"
    _nvim_env_rmr "${XDG_CONFIG_HOME:-$HOME/.config}/nvim-$target" || return 1
    _nvim_env_rmr "${XDG_DATA_HOME:-$HOME/.local/share}/nvim-$target" || return 1
    _nvim_env_rmr "${XDG_STATE_HOME:-$HOME/.local/state}/nvim-$target" || return 1
    _nvim_env_rmr "${XDG_CACHE_HOME:-$HOME/.cache}/nvim-$target" || return 1
}

alias nvimenv=nvim_env
alias nvenv=nvim_env
