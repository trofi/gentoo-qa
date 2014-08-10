#!/bin/bash

find . -type f -name '*.ebuild' | while read e
do
    while read l
    do
        # 20 ebuilds have "etc."
        # http://git.overlays.gentoo.org/gitweb/?p=proj/portage.git;a=commitdiff;h=bbb34efebd0bfc0b231073d00b863b3e3ebd918a
        [[ $l == 'DESCRIPTION='*'etc."' ]] && continue

        if [[ $l == 'DESCRIPTION='*'."' ]]; then
            echo "$e: fixing '.' in description"
            sed -i -e '/^DESCRIPTION=/ { s/."$/"/ }' "$e"
        fi
    done < "$e"
done
