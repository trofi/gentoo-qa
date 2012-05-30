#!/bin/bash

# the EAPI= line validator (https://bugs.gentoo.org/402167)

# parse args

be_verbose=
dump_errors=
get_opt() {
    local result=0
    case "$1" in
        --verbose)      be_verbose=yes ;;
        --dump-errors) dump_errors=yes ;;
        --) result=1 ;;
        --) echo "WARN: unknown option '$1'"; result=1 ;;
        *) result=1 ;;
    esac

    return $result
}

v() { [[ -n $be_verbose ]] && echo "$@"; }

while get_opt "$1"; do
    shift
done

[[ -z $1 ]] && {
    echo "usage: $0 [--verbose] [--dump-errors] <ebuild-tree>..."
    exit 1
}

# real work

expect() {
    local e_name=$1
    local expected=$2
    local actual

    read -r actual
    [[ $actual == $expected ]] || echo "$e_name: HEADER MISMATCH: expected '$expected' got '$actual'"
}

errors_file=$(mktemp)
for ebuild_tree in "$@"; do

    find "$ebuild_tree" -type f -name '*.ebuild' | while read e
    do
        v "TEST: $e"
        l=
        {
            # yes, we are stricter, than needed.
            # we require exactly 5th line
            expect "$e 1:" "# Copyright 1999-* Gentoo Foundation"
            expect "$e 2:" "# Distributed under the terms of the GNU General Public License v2"
            expect "$e 3:" "# $Header*"
            expect "$e 4:" ""
            expect "$e 5:" "EAPI=*"
        } <"$e"
    done
done
rm -f "$errors_file"
