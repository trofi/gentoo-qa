#!/bin/bash

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

errors_file=$(mktemp)
for ebuild_tree in "$@"; do

    find "$ebuild_tree" -type f -name '*.ebuild' | while read e
    do
        v "TEST: $e"
        ebuild "$e" clean

        NO_GITIFY=yes FEATURES=noauto \
        ebuild "$e" fetch unpack prepare \
             >"$errors_file" 2>&1 \
          || { echo "FAILED: $e"; [[ -n $dump_errors ]] && cat "$errors_file"; }
        ebuild "$e" clean
    done
done
rm -f "$errors_file"
