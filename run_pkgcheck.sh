#!/bin/bash

# yield CPU to all interactive tasks
chrt --batch --pid 0 $$

# checks for keywords mismatch treewide with pkgcheck
# I run it as:
#    ./run_pkgcheck.sh --arches=-x64-macos
# Or for specific arch as:
#    ./run_pkgcheck.sh --arches=sparc --profiles=default/linux/sparc/17.0
# To check tree for consistency a few more checks can be dropped:
#    DISABLE_EXTRA_KEYWORDS=DroppedKeywords ./run_pkgcheck.sh --arches=sparc --profiles=default/linux/sparc/17.0

: ${DISABLE_EXTRA_KEYWORDS=}

# Not too critical for now. I'd like to keep only arch-specific warnings.
DISABLED_KEYWORDS=(
    # up to maintainer to fix, not arch team
    AbsoluteSymlink

    BadDescription
    BadFilename
    BannedEapiCommand

    DeprecatedDep
    DeprecatedEapi
    DeprecatedEapiCommand
    DeprecatedEclass
    DeprecatedInsinto
    DoubleEmptyLine
    DoublePrefixInPath
      LaggingStable
    DuplicateFiles

    EclassDocError
    EclassDocMissingFunc
    EclassDocMissingVar

    ExecutableFile

    LiveOnlyPackage

    MaintainerNeeded
    MatchingChksums
    MissingLicenseRestricts
    MissingPackageRevision
    MissingPythonEclass
    MissingSlash
    MissingSlotDep
    MissingTestRestrict
    MissingUnpackerDep
    MissingUri
    MissingUseDepDefault
    MultiMovePackageUpdate
    MultipleKeywordsLines

    NoFinalNewline
    NonGentooAuthorsCopyright
    NonexistentBlocker
    NonexistentDeps

    ObsoleteUri
    OldGentooCopyright
    OutdatedBlocker

    PkgMetadataXmlEmptyElement
    PkgMetadataXmlIndentation
    PkgMetadataXmlInvalidPkgRef
    PotentialGlobalUse
    PotentialLocalUse
    PotentialStable
    ProbableGlobalUse
    PythonCompatUpdate
    PythonMissingDeps
    PythonMissingRequiredUse
    PythonRuntimeDepInAnyR1

    ReadonlyVariable
    RedundantDodir
    RedundantLongDescription
    RedundantVersion
    RedundantUriRename
    RequiredUseDefaults
    ReferenceInMetadataVar

    SizeViolation
    StableRequest
    StaticSrcUri

    TarballAvailable
    TrailingEmptyLine

    UncheckableDep
    UnknownManifest
    UnknownProfilePackageUse
    UnknownProfileUse
    UnknownRestrict
    UnderscoreInUseFlag
    UnnecessarySlashStrip
    UnsortedKeywords
    UnstableOnly
    UnusedEclasses
    UnusedLicenses
    UnusedProfileDirs

    VariableScope
    VulnerablePackage

    WhitespaceFound
)

DISABLED_KEYWORDS+=(
    ${DISABLE_EXTRA_KEYWORDS}
)

# -foo,-bar
keywords=${DISABLED_KEYWORDS[@]/#/-}
keywords=${keywords// /,}

pkgcheck scan --keywords="${keywords}" -r gentoo "$@"
