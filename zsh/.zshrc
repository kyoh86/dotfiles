#!/bin/sh

function _source_if() {
    if [ -f ${1} ]; then
        source ${1}
    else
        echo "not found: ${1}"
    fi
}

function _source_part() {
    _source_if ${ZDOTDIR}/part/${1}.zsh
}

_source_part _init

# ZSHRC 終了処理 {{{
# ------------------------------------------------------------------------------
export PATH=".:${PATH}"

# ZSHRC コンパイル{{{
if [ ! -e ${ZDOTDIR:-${HOME}}/.zshrc.zwc ] || [ ${ZDOTDIR:-${HOME}}/.zshrc -nt ${ZDOTDIR:-${HOME}}/.zshrc.zwc ]; then
    zcompile ${ZDOTDIR:-${HOME}}/.zshrc
fi
# }}}

# ZSHRC性能検査 {{{
# if (which zprof > /dev/null) ;then
#   zprof | less
# fi
# }}}

# }}}

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
