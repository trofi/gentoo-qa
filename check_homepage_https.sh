#!/bin/bash -e

check_homepage() {
    local hp=$1

    hsp=${hp/\"http:/\"https:}

    if [[ $pn != $hp ]]; then
        echo "FIX HOMEPAGE HTTPS: $e"
        sed -e "/HOMEPAGE/ s/\"http:/\"https:/" -i "${e}"
    fi
}

find . -type f -name '*.ebuild' | while read e
do
    homepage=

    while read l
    do
        [[ $l == *"HOMEPAGE="*"http://github.com/"* ]] && homepage=$l
        [[ $l == *"HOMEPAGE="*"http://www.github.com/"* ]] && homepage=$l
        [[ $l == *"HOMEPAGE="*"http://bitbucket.org/"* ]] && homepage=$l

        if [[ -n $homepage ]]; then
            check_homepage "$homepage"
            break
        fi
    done < "$e"
done
