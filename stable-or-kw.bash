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

warn() {
    echo "WARNING: $@"
}

todo_list=stable-or-kw.list

if [ $# = 1 ]; then
    todo_list=${1}
fi

while read l; do
    # up to next bug
    if [[ $l == "# bug #"* ]]; then
        bug_number=${l#\# bug \#}
        continue
    fi
    # sticky
    if [[ $l == "# credit: "* ]]; then
        credit=${l#\# credit: }
        continue
    fi
    if [[ -z $l ]]; then
        # bugs are directly attached to atom lists
        bug_number=
        continue
    fi
    if [[ $l = "#"* ]]; then
        warn "skipping unknown comment: '${l}'"
        continue
    fi
    if [[ $l != "="* ]]; then
        die "unknown directive: '${l}'"
    fi
    if [[ -z $bug_number ]]; then
        warn "unset bug comment"
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
        commitfile=$(mktemp)
        cat >"${commitfile}" <<EOF
${cat}/${pn}: ${action} ${pv} for ${arch}

${action} wrt bug #${bug_number}
${credit:+Tested-by: ${credit}}
EOF

        repoman_opts=(
            -d
            -e y
            --include-arches="${kws_no_tilde}"
            --quiet
            --commitmsgfile="${commitfile}"
        )

        run repoman commit "${repoman_opts[@]}" || echo FAILED
        run rm "${commitfile}"
    )
done <"${todo_list}"
