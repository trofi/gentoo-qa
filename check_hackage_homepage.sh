#!/bin/bash -e

check_homepage() {
    local hp=$1
    local pn=$2

    hp=${hp#HOMEPAGE=\"}
    hp=${hp%\"}
    hp=${hp#http://hackage.haskell.org/package/}
    hp=${hp#http://hackage.haskell.org/cgi-bin/hackage-scripts/package/}

    pn=${pn#MY_PN=}
    pn=${pn#\"}
    pn=${pn%\"}
    if [[ $pn != $hp ]]; then
        echo "FIX HACKAGE HOMEPAGE: $e: ${hp} -> ${pn}"
        sed -e "/HOMEPAGE/ s/$hp/$pn/" -i "${e}"
    fi
}

find . -type f -name '*.ebuild' | while read e
do
    my_pn=
    homepage=

    while read l
    do
        [[ $l == *"HOMEPAGE="*"hackage"* ]] && homepage=$l
        [[ $l == *"MY_PN="*              ]] &&    my_pn=$l

        if [[ -n $my_pn ]] && [[ -n $homepage ]]; then
            check_homepage "$homepage" "$my_pn"
            break
        fi
    done < "$e"
done
