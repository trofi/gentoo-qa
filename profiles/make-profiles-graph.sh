#!/bin/bash

profile_root=$(portageq envvar PORTDIR)/profiles
profile_root=$(realpath "${profile_root}")

profile_tree() {
    local src_profile=$1
    local src_profile_name=${src_profile#${profile_root}/}
    local dst_p
    local dst_profile
    local dst_profile_name

    [[ -f "$1/parent" ]] || return

    while read dst_p; do
        if [[ $dst_p != *"#"* ]]; then
            dst_profile=$(realpath "${src_profile}/${dst_p}")
            dst_profile_name=${dst_profile#${profile_root}/}

            echo "    \"${src_profile_name}\" -> \"${dst_profile_name}\""
            profile_tree "${dst_profile}"
        fi
    done < "$1/parent"
}

{
echo "digraph profiles {"

for p in "$@"
do
    profile_tree "${profile_root}/$p"
done | sort -u

echo "}"
} > profiles.dot
dot -Tpng profiles.dot > profiles.png
