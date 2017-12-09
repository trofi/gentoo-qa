#!/bin/bash -e

# The tool grabs stablereq and keywordreq bugs for all architectures
# and outputs which ones are already done.

ARCHES=(
    ia64
    hppa
    ppc
    ppc64
    sparc
)

CACHE_DIR=$(pwd)/kw-cache
STABLE_DIR=${CACHE_DIR}/stablereq
KEYWORD_DIR=${CACHE_DIR}/keywordreq

debug() {
    echo "DEBUG: $@" >&2
}

info() {
    echo "INFO: $@" >&2
}

warn() {
    echo "WARNING: $@" >&2
}

getatoms() {
    # --no-depends --no-sanity-check
    set -- getatoms.py "$@"
    info "$@"
    "$@" || warn "getatoms.py failed. Empty output?"
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
    local package=$1 keyword=$2 kw
    for kw in $(portageq metadata / ebuild ${package} KEYWORDS); do
        if [[ ${keyword} == ${kw} ]]; then
            # keyword is already present
            return 0
        fi
    done
    return 1
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
                if ! check_keyword_presence "${line#=}" "${keyword}"; then
                    # at least one atom is missing keywords
                    stale_bug=no
                fi
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
    refresh_lists

    find_stale_bugs
}

main "$@"
