#!/bin/bash

# example usage:
#   PROJECTS=slyfox ./run_pkgcheck_for_maintained.sh --keywords=StableRequest

: ${PROJECTS:=}
: ${REPO:=gentoo}

: ${DISABLE_EXTRA_KEYWORDS=}

DISABLED_KEYWORDS=(
    # Some packages will never be stable.
    UnstableOnly
    # Some arches will never be stable subset of packages.
    PotentialStable
    # Ongoing stabilization
    LaggingStable
    # Many broken depends
    NonsolvableDepsInExp
)

DISABLED_KEYWORDS+=(
    ${DISABLE_EXTRA_KEYWORDS}
)

# -foo,-bar
keywords=${DISABLED_KEYWORDS[@]/#/-}
keywords=${keywords// /,}

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
ACCEPT_KEYWORDS='**' portageq --no-regex --no-version --maintainer-email="${emails[*]/%/@gentoo.org}" --repo=${REPO} | xargs --no-run-if-empty pkgcheck scan --keywords="${keywords}" --repo=gentoo "$@" --
