#!/bin/sh

find . '(' '(' -name '*.zsh' \
  -o -name '.zlogin*' -o -name 'zlogin*' \
  -o -name '.zlogout*' -o -name 'zlogout*' \
  -o -name '.zprofile*' -o -name 'zprofile*' \
  -o -path '*/.zsh*' -o -path '*/zsh*' \
  ')' -a -not -name '*.zwc' \
  \
  -o -name '*.sh' \
  -o -path '*/.profile*' -o -path '*/profile*' \
  -o -path '*/.shlib*' -o -path '*/shlib*' \
  ')' -exec shellcheck {} + || exit

# shellcheck disable=SC2016
find . -type f ! -name '*.*' -perm /111 -exec sh -c '
        for f
        do
            head -n1 "$f" | grep -Eqs "^#! */[^ ]*/[abkz]*sh" || continue
            shellcheck "$f" || err=$?
        done
        exit $err
        ' _ {} +
