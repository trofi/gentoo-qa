#!/bin/bash

[[ -z $1 ]] && {
    echo "usage $0 <ebuild-tree>"
    exit 1
}

tree_root=$1

shopt -s nullglob

for c in $(< "$tree_root/profiles/categories"); do
    for pkg in "$tree_root"/$c/*; do
        len() { echo ${#@}; }
        [[ $pkg != */CVS ]] &&
        [[ $pkg != */metadata.xml ]] &&
            echo "$(len "${pkg}"/*.ebuild) ${pkg#${tree_root}/}"
    done
done | sort -r -n -k1
