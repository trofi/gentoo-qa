#!/bin/bash

# checks for keywords mismatch treewide with pkgcheck
# I run it as:
#    ./run_pkgcheck.sh --glsa-dir=${HOME}/portage/glsa --arches=-x64-macos
# Or for specific arch as:
#    ./run_pkgcheck.sh --glsa-dir=${HOME}/portage/glsa --arches=sparc --profiles=default/linux/sparc/17.0

# Not too critical for now. I'd like to keep only arch-specific warnings.
DISABLED_KEYWORDS=(
    # up to maintainer to fix, not arch team
    AbsoluteSymlink
    BadInsIntoDir
    BadDescription
    DeprecatedEAPI
    DeprecatedEclass
    DuplicateFiles
    ExecutableFile
    HttpsAvailable
    MatchingGlobalUSE
    MissingRevision
    MissingSlash
    MissingSlotDep
    MissingUseDepDefault
    NonExistentDeps
    ProbableGlobalUSE
    ProbableUSE_EXPAND
    RedundantVersion
    RequiredUseDefaults
    SizeViolation
    StaleUnstable
    UnnecessarySlashStrip
    UnsortedKeywords
    UnstableOnly
    VulnerablePackage
    WhitespaceFound
)

# Deprecated and problematic profiles.
DISABLED_PROFILES=(
    # These profiles don't inherit arch-generic masks
    # and thus have many inconsistent dependencies.
    # These dev/exp profiles are to be deprecated and
    # removed:
    #    https://bugs.gentoo.org/673276
    hardened/linux/arm/armv6j
    hardened/linux/arm/armv7a
    hardened/linux/ia64
    hardened/linux/mips/mipsel/multilib/n32
    hardened/linux/mips/mipsel/multilib/n64
    hardened/linux/mips/mipsel/n32
    hardened/linux/mips/mipsel/n64
    hardened/linux/mips/multilib/n32
    hardened/linux/mips/multilib/n64
    hardened/linux/mips/n32
    hardened/linux/mips/n64
    hardened/linux/powerpc/ppc32
    hardened/linux/powerpc/ppc64/32bit-userland
    hardened/linux/powerpc/ppc64/64bit-userland
    hardened/linux/musl/arm/armv7a
    hardened/linux/musl/arm64
    hardened/linux/musl/mips
    hardened/linux/musl/mips/mipsel
    hardened/linux/musl/ppc
    hardened/linux/uclibc/arm/armv7a
    hardened/linux/uclibc/mips
    hardened/linux/uclibc/mips/mipsel
    hardened/linux/uclibc/ppc
)

# -foo,-bar
keywords=${DISABLED_KEYWORDS[@]/#/-}
keywords=${keywords// /,}

# -foo,-bar
profiles=${DISABLED_PROFILES[@]/#/-}
profiles=${profiles// /,}

pkgcheck --keywords="${keywords}" --profiles=${profiles} "$@"
