#!/bin/bash

# The tool grabs stablereq and keywordreq bugs for all architectures
# and outputs which ones are already done.

ARCHES=(
    # stable
    alpha
    amd64
    arm
    hppa
    ia64
    ppc
    ppc64
    x86

    # unstable
    arm64
    mips

    # experimental
    m68k
    nios2
    riscv
    s390
    sh
    sparc
)

CACHE_DIR=$(pwd)/kw-cache
STABLE_DIR=${CACHE_DIR}/stablereq
KEYWORD_DIR=${CACHE_DIR}/keywordreq

# command line tunables
DEBUG=no
VERBOSE=no
REFRESH_LISTS=yes

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

getatoms() {
    # --no-depends --no-sanity-check
    set -- getatoms.py "$@"
    info "$@"
    "$@" || info "getatoms.py failed. Empty output?"
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
    # TODO: maybe don't rerun if cache is not too old (+/- a few minutes)
    #warn "skipping bug refresh"
    #return 0

    mkdir -pv "${STABLE_DIR}"
    mkdir -pv "${KEYWORD_DIR}"

    local arch
    for arch in "${ARCHES[@]}"; do
        getatoms --arch "${arch}" --stablereq  --all-bugs > "$(stable_file "${arch}")"
        getatoms --arch "${arch}" --keywordreq --all-bugs > "$(keywords_file "${arch}")"
    done
}

check_keyword_presence() {
    local package=$1 keyword=$2 kw keywords
    keywords=$(portageq metadata / ebuild ${package} KEYWORDS)
    if [[ $? -ne 0 ]]; then
        echo "BAD"
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
    local keyword=$1 kw_file=$2 bug= stale_bug= line=

    # Assume input in form of:
    # '# bug #<number>'
    # '=${CATEGORY}/${PF}'
    # '=${CATEGORY}/${PF}'
    # '<newline or EOF>'

    check_and_report_staleness() {
        if [[ ${stale_bug} == yes ]]; then
            echo "STALE BUG: bug=${bug} keyword=${keyword}"
        fi
        bug=
        stale_bug=
    }

    while read line; do
        case "${line}" in
            '# bug #'*)
                bug=${line#\# bug #}
                stale_bug=yes
                ;;
            '='*)
                case "$(check_keyword_presence "${line#=}" "${keyword}")" in
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
                        warn "missing packages in bug=${bug}"
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

    [[ $REFRESH_LISTS = yes ]] && refresh_lists

    find_stale_bugs
}

main "$@"
