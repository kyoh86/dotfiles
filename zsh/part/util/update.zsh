# update all

function update {
    set -e
    if (($# > 0)); then
        while (($# > 0)); do
            update_$1
            shift
        done
    else
        update_apt
        update_paru
        update_asdf
        update_gordon
        update_go
        update_rust
        update_coursier
        update_neovim
        echo "done"
    fi
}

# update apt {{{
function update_apt {
    echo updating apt
    pushd ~
    if command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt upgrade -y
    fi
    popd
}
# }}}

# update paru {{{
function update_paru {
    echo updating paru
    pushd ~
    if command -v paru >/dev/null 2>&1; then
        zsh -c 'paru -Syyu --skipreview --clean --noconfirm'
    fi
    popd
}
# }}}

# update asdf {{{
function update_asdf {
    echo updating asdf
    pushd ~
    if command -v asdf >/dev/null 2>&1; then
        asdf plugin-update --all
    fi
    popd
}
# }}}

# update gordon {{{
function update_gordon {
    echo updating gordon
    pushd ~
    if command -v gordon >/dev/null 2>&1; then
        gordon update --all
    fi
    popd
}
# }}}

# update go/bin {{{
function update_go {
    echo updating go
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
    echo updating rust
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
    echo updating coursier
    pushd ~
    if command -v coursier >/dev/null 2>&1; then
      coursier list | xargs -n1 coursier update
    fi
    popd
}
# }}}

# update neovim {{{
function update_neovim {
    echo updating neovim
    eval "$(luarocks --lua-version=5.1 path)"
    nvim_tmpdir="$(mktemp -d)"
    trap "sudo rm -rf $nvim_tmpdir" EXIT
    git clone --depth 1 -b nightly https://github.com/neovim/neovim "$nvim_tmpdir/neovim"
    pushd "$nvim_tmpdir/neovim"
    if command -v nvim >/dev/null 2>&1; then
        current="$(nvim --version | head -n1 | awk -F' |-' '{print $4}')"
        latest="$(git reflog show HEAD | head -n1 | awk '{print $1}')"
        if [ "${current}" = "${latest}" ]; then
            echo "it's up to date"
            return 1
        fi
    fi
    echo make
    make CMAKE_BUILD_TYPE=Release
    echo install
    sudo make CMAKE_BUILD_TYPE=Release install
    popd
}
# }}}

