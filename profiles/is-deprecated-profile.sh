#!/bin/bash

profile_root=$(portageq envvar PORTDIR)/profiles
profile_root=$(realpath "${profile_root}")

for p in "$@"; do
    echo -n "${p} "
    d=${profile_root}/${p}/deprecated

    if [[ -f ${d} ]]; then
        echo "DEPRECATED $(cat "${d}")"
    else
        echo "ACTIVE"
    fi
done
