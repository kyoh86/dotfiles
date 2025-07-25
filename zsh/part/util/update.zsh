# update all

function update {
    if (($# > 0)); then
        while (($# > 0)); do
            update_$1
            shift
        done
    else
        update_apt || return 1
        update_paru || return 1
        update_brew || return 1
        update_mise || return 1
        update_deno || return 1
        update_go || return 1
        update_rust || return 1
        update_coursier || return 1
        update_neovim || return 1
        echo "done"
    fi
}

# NOTE: 各所でsudo echoしているのは、sudoのセッション維持のため

# update apt {{{
function update_apt {
    sudo echo updating apt
    pushd ~
    if command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt upgrade -y
    fi
    popd
}
# }}}

# update paru {{{
function update_paru {
    sudo echo updating paru
    pushd ~
    if command -v paru >/dev/null 2>&1; then
        zsh -c 'paru -Syyu --skipreview --noconfirm'
    fi
    popd
}
# }}}

# update brew {{{
function update_brew {
    sudo echo updating brew
    pushd ~
    if command -v brew >/dev/null 2>&1; then
        zsh -c 'brew update'
        zsh -c 'brew upgrade'
    fi
    popd
}
# }}}

# update mise {{{
function update_mise {
    sudo echo updating mise
    pushd ~
    if command -v mise >/dev/null 2>&1; then
        mise self-update --yes
        mise upgrade --yes
        mise prune --yes
    fi
    popd
}
# }}}

# update deno {{{
function update_deno {
    sudo echo updating deno
    pushd ~
    if [ "${HOME}/.deno/bin/deno" = "$(command -v deno)" ]; then
        sudo deno upgrade
    fi
    popd
}
# }}}

# update go/bin {{{
function update_go {
    sudo echo updating go
    if command -v go >/dev/null 2>&1; then
        pushd ~
        local gobin="$(go env GOBIN)"
        local gobin="${gobin:-$(go env GOPATH)/bin}"
        print -rl ${gobin}/*(*) | while read file; do
            local pkg="$(go version -m "$file" | head -n2 | tail -n1 | awk '{print $2}')"
            go install $pkg@latest
        done
        popd
    fi
}
# }}}

# update rust {{{
function update_rust {
    sudo echo updating rust
    pushd ~
    if command -v rustup >/dev/null 2>&1; then
        rustup update
    fi
    if command -v cargo >/dev/null 2>&1; then
        if [ "$(cargo install --list | perl -ne'/^([\w-]+) v[\d.]+:$/&&print"$1\n"' | wc -l)" != "0" ]; then
            cargo install "$(cargo install --list | perl -ne'/^([\w-]+) v[\d.]+:$/&&print"$1\n"')"
        fi
    fi
    popd
}
# }}}

# update coursier (scala) {{{
function update_coursier {
    sudo echo updating coursier
    pushd ~
    if command -v coursier >/dev/null 2>&1; then
      coursier list | xargs -n1 coursier update
    fi
    popd
}
# }}}

# update neovim {{{
function update_neovim {
    sudo echo updating neovim
    eval "$(luarocks --lua-version=5.1 path)"
    nvim_tmpdir="$(mktemp -d)"
    trap "sudo rm -rf $nvim_tmpdir" EXIT
    echo cloning neovim
    git -c advice.detachedHead=false clone --depth 1 -b nightly https://github.com/neovim/neovim "$nvim_tmpdir/neovim"
    pushd "$nvim_tmpdir/neovim"
    if [ -n "$NVIM_PINNED_COMMIT" ]; then
        echo "!!NEOVIM PINNED!!"
        git fetch --depth 1 origin "$NVIM_PINNED_COMMIT"
        git reset --hard FETCH_HEAD
    fi
    if command -v nvim >/dev/null 2>&1; then
        current="$(nvim --version | head -n1 | awk -F' |-' '{print $4}')"
        latest="$(git reflog show HEAD | head -n1 | awk '{print $1}')"
        if [ "${current}" = "${latest}" ]; then
            echo "it's up to date"
            popd
            return 0
        fi
    fi
    echo clean
    sudo rm -r /usr/local/share/nvim/
    echo make
    make CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=/usr/local"
    echo install
    sudo make install
    popd
}
# }}}
