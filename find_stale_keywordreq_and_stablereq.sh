#!/bin/bash

# The tool grabs stablereq and keywordreq bugs for all architectures
# and outputs which ones are already done.

ARCHES=(
    # stable
    amd64
    arm
    hppa
    ppc
    ppc64
    x86

    # unstable
    alpha
    arm64
    ia64
    mips

    # experimental
    m68k
    riscv
    s390
    sparc
)

CACHE_DIR=$(pwd)/kw-cache
STABLE_DIR=${CACHE_DIR}/stablereq
KEYWORD_DIR=${CACHE_DIR}/keywordreq
EROOT=$(portageq envvar EROOT)

# command line tunables
DEBUG=no
VERBOSE=no
REFRESH_LISTS=yes
METADATA_ONLY=no
EXTRA_NATTKA_PARAMS=
EXTRA_NATTKA_APPLY_PARAMS=

parse_opts() {
    for o in "$@"; do
        case "$o" in
            --debug=yes)
                DEBUG=yes
                ;;
            --verbose=yes)
                VERBOSE=yes
                ;;
            --refresh-lists=no)
                REFRESH_LISTS=no
                ;;
            --metadata-only=yes)
                METADATA_ONLY=yes
                ;;
            --only-arches=*)
                ARCHES=( ${o#--only-arches=} )
                ;;
            --nattka-params=*)
                EXTRA_NATTKA_PARAMS=${o#--nattka-params=}
                ;;
            --nattka-apply-params=*)
                EXTRA_NATTKA_APPLY_PARAMS=${o#--nattka-apply-params=}
                ;;
            *)
                warn "unknown option '$o'"
                ;;
        esac
    done
}

debug() {
    [[ $DEBUG = yes ]] && echo "DEBUG: $@" >&2
}

info() {
    [[ $VERBOSE = yes ]] && echo "INFO: $@" >&2
}

warn() {
    echo "WARNING: $@" >&2
}

stable_file() {
    local arch=$1
    echo "${STABLE_DIR}/${arch}.list"
}

keywords_file() {
    local arch=$1
    echo "${KEYWORD_DIR}/${arch}.list"
}

refresh_lists() {
    if [[ $REFRESH_LISTS != yes ]]; then
        warn "Skip refresh"
        return 0
    fi

    mkdir -pv "${STABLE_DIR}"
    mkdir -pv "${KEYWORD_DIR}"

    local arch
    for arch in "${ARCHES[@]}"; do
        nattka ${EXTRA_NATTKA_PARAMS} apply --stablereq  --arch "${arch}" ${EXTRA_NATTKA_APPLY_PARAMS} -n > "$(stable_file   "${arch}")" &
        nattka ${EXTRA_NATTKA_PARAMS} apply --keywordreq --arch "${arch}" ${EXTRA_NATTKA_APPLY_PARAMS} -n > "$(keywords_file "${arch}")" &
    done
    wait
}

REPO_ROOT=$(portageq get_repo_path "${EROOT}" gentoo)
get_keywords() {
    local package=$1 metadata_file=${REPO_ROOT}/metadata/md5-cache/${package}

    if [[ ${METADATA_ONLY} == no ]]; then
        portageq metadata "${EROOT}" ebuild ${package} KEYWORDS
        return
    fi

    # No file
    if [[ ! -f ${metadata_file} ]]; then
        echo "no package '${package}'"
        return 1
    fi

    local l
    while read l; do
        if [[ ${l} == "KEYWORDS="* ]]; then
            echo "${l#KEYWORDS=}"
            return
        fi
    done <"${metadata_file}"
}

check_keyword_presence() {
    local package=$1 keyword=$2 kw keywords
    keywords=$(get_keywords "${package}")
    if [[ $? -ne 0 ]]; then
        echo "BAD: ${keywords}"
        return
    fi
    for kw in ${keywords}; do
        if [[ ${keyword} == ${kw} ]]; then
            # keyword is already present
            echo "PRESENT"
            return
        fi
        if [[ ${keyword} == ~${kw} ]]; then
            # ~arch requested, arch is present
            echo "ALREADY_STABLE"
            return
        fi
    done
    echo "MISSING"
}

find_stale_bugs_for_keyword() {
    local keyword=$1 kw_file=$2 bug= stale_bug= line= pkg=

    # Assume input in form of:
    # '# bug #<number>'
    # '=${CATEGORY}/${PF}'
    # '=${CATEGORY}/${PF}'
    # '<newline or EOF>'

    check_and_report_staleness() {
        if [[ ${stale_bug} == yes ]]; then
            echo "STALE BUG: bug=https://bugs.gentoo.org/${bug} keyword=${keyword}"
        fi
        bug=
        pkg=
        stale_bug=
    }

    while read line; do
        case "${line}" in
            '# bug #'*)
                bug=${line#\# bug #}
                stale_bug=yes
                ;;
            '# bug '*' (KEYWORDREQ)'|'# bug '*' (STABLEREQ)')
                bug=${line#\# bug }
                bug=${bug// *}
                stale_bug=yes
                ;;
            '='*)
                pkg=${line#=}
                pkg=${pkg// *}
                local keyword_presence="$(check_keyword_presence "${pkg}" "${keyword}")"
                case "${keyword_presence}" in
                    "MISSING")
                        # at least one keyword is missing. bug is ok
                        stale_bug=no
                        ;;
                    "PRESENT")
                        # ignore already done item
                        ;;
                    "ALREADY_STABLE")
                        # ignore already done item
                        #warn "KEYWORDREQ for already stable '${line}' in bug=${bug}"
                        ;;
                    *)
                        # this bug also has work to do but needs tweaks
                        # in package list
                        stale_bug=no
                        warn "BUG: bug=https://bugs.gentoo.org/${bug} ${keyword_presence}"
                        ;;
                esac
                ;;
            '')
                # '<newline>' is reached
                check_and_report_staleness
                ;;
            *)
                warn "failed to interpret '${line}'"
                ;;
        esac
    done < "${kw_file}"
    # '<EOF>' is reached
    check_and_report_staleness
}

find_stale_bugs() {
    local arch
    for arch in "${ARCHES[@]}"; do
        info "Checking for keyword staleness for '${arch}'"
        find_stale_bugs_for_keyword  "${arch}" "$(stable_file "${arch}")"
        find_stale_bugs_for_keyword "~${arch}" "$(keywords_file "${arch}")"
    done
}

main() {
    parse_opts "$@"

    refresh_lists

    find_stale_bugs
}

main "$@"
