#!/bin/bash -e

check_src_uri() {
    local e=$1

    echo "FIX HACKAGE SRC_URI: $e"
    sed -e "/SRC_URI/ s,http://hackage.haskell.org/,mirror://hackage/," -i "${e}"
}

while read e; do
    src_uri=

    while read l
    do
        if [[ $l == *'SRC_URI="http://hackage.haskell.org'* ]]; then
            check_src_uri "$e"
            break
        fi
    done < "$e"
done < <(find . -type f -name '*.ebuild')
