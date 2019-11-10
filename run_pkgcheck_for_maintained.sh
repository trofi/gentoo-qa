#!/bin/bash

: ${PROJECTS:=}
: ${REPO:=gentoo}

# Grab project list from:
#     https://wiki.gentoo.org/wiki/User:Slyfox
emails=(
    # personal
    slyfox

    # non-arch projects
    crossdev
    haskell
    toolchain

    # arch projects
    hppa
    ia64
    ppc
    ppc64
    powerpc
    riscv
    sparc

    # for completeness
    council
)

[[ -n ${PROJECTS} ]] && emails=( ${PROJECTS} )

IFS=,
# (foo bar) -> "foo@bentoo.org,bar@gentoo.org"
portageq --maintainer-email="${emails[*]/%/@gentoo.org}" --repo=${REPO} | awk '{ print "="$0 }' | xargs --no-run-if-empty pkgcheck scan --repo=gentoo
