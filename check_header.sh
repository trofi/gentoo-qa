#!/bin/bash -e

# ::gentoo main tree switched to git recently
# As a result ebuild header hac changed a bit:
#    # $Header: /var/cvsroot/gentoo-x86/eclass/ghc-package.eclass,v 1.34 2012/09/14 02:51:23 gienah Exp $
# now became just an
#    # $Id$

check_header() {
    local e=$1

    echo 'FIX "# $Header:" in: '"$e"
    sed -e 's/^# \$Header: .*\$$/# $Id$/g' -i "${e}"
}

while read e; do
    while read l
    do
        if [[ $l == '# $Header:'* ]]; then
            check_header "$e"
            break
        fi
    done < "$e"
done < <(find . -type f)
