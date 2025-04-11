# mise
eval "$(/home/kyoh86/.local/bin/mise activate zsh)"

# direnv
if command -v direnv >/dev/null 2>&1; then
    eval "$(command direnv hook zsh)"
fi

# Lua
if command -v luarocks >/dev/null 2>&1; then
    eval "$(luarocks --lua-version=5.1 path)"
fi

# SDKMAN
[[ -s "${HOME}/.sdkman/bin/sdkman-init.sh" ]] && source "${HOME}/.sdkman/bin/sdkman-init.sh"

# LANG
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
