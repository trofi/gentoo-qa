#!/bin/bash

# checks for keywords mismatch treewide with pkgcheck
# I run it as:
#    ./run_pkgcheck.sh --arches=-x64-macos
# Or for specific arch as:
#    ./run_pkgcheck.sh --arches=sparc --profiles=default/linux/sparc/17.0

# Not too critical for now. I'd like to keep only arch-specific warnings.
DISABLED_KEYWORDS=(
    # up to maintainer to fix, not arch team
    AbsoluteSymlink

    BadDescription
    BannedEapiCommand

    DeprecatedEapi
    DeprecatedEapiCommand
    DeprecatedEclass
    DeprecatedInsinto
    DeprecatedPkg
    DoublePrefixInPath
      # This one is frequently useful
      DroppedKeywords
      LaggingStable
    DuplicateEclassInherits
    DuplicateFiles

    ExecutableFile

    MatchingChksums
    MissingLicenseRestricts
    MissingPackageRevision
    MissingSlash
    MissingSlotDep
    MissingTestRestrict
    MissingUnpackerDep
    MissingUri
    MissingUseDepDefault
    MissingVirtualKeywords

    NonexistentBlocker
    NonexistentDeps

    ObsoleteUri
    OldGentooCopyright
    OutdatedBlocker

    PotentialGlobalUse
    PotentialLocalUse
    PotentialStable
    ProbableGlobalUse

    RedundantDodir
    RedundantLongDescription
    RedundantVersion
    RedundantUriRename
    RequiredUseDefaults

    SizeViolation
    StableRequest
    StaticSrcUri

    TarballAvailable

    UncheckableDep
    UnknownProfilePackageUse
    UnknownProfilePackages
    UnknownProfileUse
    UnderscoreInUseFlag
    UnnecessarySlashStrip
    UnsortedKeywords
    UnstableOnly
    UnusedEclasses
    UnusedLicenses
    UnusedProfileDirs

    VulnerablePackage

    WhitespaceFound
)

# -foo,-bar
keywords=${DISABLED_KEYWORDS[@]/#/-}
keywords=${keywords// /,}

pkgcheck scan --keywords="${keywords}" -r gentoo "$@"
