#!/bin/bash

# Use as:
#     refresh-kw.bash > /etc/portage/package.accept_keywords/to-keyword; cat /etc/portage/package.accept_keywords/to-keyword
LANG=en_US.UTF-8 nattka --repo /bound/portage apply -n --keywordreq --ignore-dependencies --ignore-sanity-check "$@"
