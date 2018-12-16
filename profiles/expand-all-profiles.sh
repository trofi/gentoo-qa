#!/bin/bash

# print each profile as a single line in order of inclusion

profile_root=$(portageq envvar PORTDIR)/profiles
profile_root=$(realpath "${profile_root}")

# extract known profiles.desc profiles
known_profiles() {
    local l
    while read l; do
        [[ $l = "#"* ]] && continue
        [[ $l = "" ]] && continue

        # example: "alpha default/linux/alpha/13.0 stable"
        set -- $l
        echo "$2"
    done < "${profile_root}/profiles.desc"
}

get_profile_tree() {
    local src_profile="$1"
    local src_profile_name=${src_profile#${profile_root}/}
    local dst_p
    local dst_profile

    echo -n " ${src_profile_name}"
    [[ -f "$1/parent" ]] || return

    while read dst_p; do
        if [[ $dst_p != *"#"* ]]; then
            # collapse foo/../bar
            dst_profile=$(realpath "${src_profile}/${dst_p}")
            get_profile_tree "${dst_profile}"
        fi
    done < "$1/parent"
}

for p in $(known_profiles); do
    get_profile_tree "${profile_root}/${p}"; echo
done
