#!/bin/bash

# TODO: needs a lot of basic improvements:
# - defend against accidental downgrade from arch to ~arch

set -e

run() {
    echo "$@"
    "$@"
}

die() {
    echo "ERROR: $@"
    exit 1
}

todo_list=stable-or-kw.list

if [ $# = 1 ]; then
    todo_list=${1}
fi

while read l; do
    if [[ $l == "# bug #"* ]]; then
        bug=${l#\# bug \#}
        continue
    fi
    if [[ $l == "# credit: "* ]]; then
        credit=" (${l#\# credit: })"
        continue
    fi
    if [[ -z $l || $l = "#"* ]]; then
        continue
    fi
    if [[ $l != "="* ]]; then
        die "unknown directive: '${l}'"
    fi
    if [[ -z $bug ]]; then
        die "unset bug comment"
    fi
    set -- ${l}
    p=$1; shift
    kws="$@"
    action="stable"
    [[ $kws == *~* ]] && action="keyworded"

    # "foo bar" -> "foo/bar"
    kws_no_tilde=${kws//\~/}
    arch=${kws_no_tilde// //}

    cat_p=${p#=}
    cat=${cat_p%\/*}
    p=${cat_p#${cat}\/}

    e=$(echo ${cat}/*/${p}.ebuild)

    pn=${e#${cat}\/}
    pn=${pn%\/*}

    pv=${p#${pn}-}

    echo "CAT: ${cat}; P: ${p}; E: ${e}; PN: ${pn}; PV: ${pv}; keywords: ${kws}"
    run ekeyword ${kws} "${e}"
    (
        cd ${cat}/${pn}
        #repoman commit --include-arches=${arch} -m "${cat}/${pn}: ${arch} stable, bug #${bug}" || echo FAILED
        run repoman commit -d -e y --include-arches="${kws_no_tilde}" --quiet -m "${cat}/${pn}: ${action} ${pv} for ${arch}, bug #${bug}${credit}" || echo FAILED
        #run repoman commit -d --include-arches="${kws_no_tilde}" --quiet -m "${cat}/${pn}: ${action} ${pv} for ${arch}, bug #${bug}${credit}" || echo FAILED
    )
done <"${todo_list}"
