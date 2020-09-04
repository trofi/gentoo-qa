#!/bin/bash

# Use as:
#     refresh-stable.bash > /etc/portage/package.accept_keywords/to-stable; cat /etc/portage/package.accept_keywords/to-stable
LANG=en_US.UTF-8 nattka --repo /bound/portage apply -n --stablereq --ignore-dependencies --ignore-sanity-check "$@"
