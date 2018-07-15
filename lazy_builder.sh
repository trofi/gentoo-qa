#!/bin/bash

# This too accepts '<todo_list>' file in 'getatoms.py' format
# and attempts to build each package with default emerge options.
#
# Build logs are piped into the '<logs_dir>' log dirs.
# Results are piped into '<output_file>' file and look like
# filtered input (to be used by 'stable-or-kw.bash' keyworder).
#
# The script attempts not to build the same atom twice to
# ease automatic incremental builds with many failures.

# Input args:

todo_list=$1
output_file=$2
logs_dir=$3

if [[ -z ${todo_list} || -z ${output_file} || -z ${logs_dir} ]]; then
    echo "usage: $0 <todo_list> <output_file> <logs_dir>"
    echo "  example: $0 /etc/portage/package.accept_keywords/to-stable /lazy.result /lazy-logs"
    exit 1
fi

if [[ ! -d ${logs_dir} ]]; then
    echo "ERROR: ${logs_dir} must be directory."
    exit 1
fi

# Internal state:

bug_number= # number
bug_header_emitted= # yes/no(empty)

emit() {
    if [[ -z $bug_header_emitted ]]; then
        echo ""
        echo "# bug #${bug_number}"
        bug_header_emitted=yes
    fi
    printf "%s\n" "${l}"
}

# Always regenerate file based on current TODO list
: > "${output_file}"
while read l; do
    # up to next bug
    if [[ $l == "# bug #"* ]]; then
        bug_number=${l#\# bug \#}
        continue
    fi

    if [[ -z $l ]]; then
        # bugs are directly attached to atom lists
        current_bug=
        bug_header_emitted=

        continue
    fi

    # foo/bar -> foo:bar
    logs_file="${logs_dir}/${l//\//:}"
    if [[ -f ${logs_file} ]]; then
        echo -n "SKIP: ${l}: "
        if [[ -f "${logs_file}.PASS" ]]; then
            echo "already PASS"
            emit "$l" >> "${output_file}"
        elif [[ -f "${logs_file}.FAIL" ]]; then
            echo "already FAIL"
        else
            echo " UNKNOWN"
        fi

    else
        # Do rebuild
        echo "BUILD: ${l}"
        set -- emerge -v1 "$l"
        echo "$@"
        { "$@" && touch "${logs_file}.PASS" || touch "${logs_file}.FAIL"; } 2>&1 | tee "${logs_file}"

        if [[ -f "${logs_file}.PASS" ]]; then
            emit "$l" >> "${output_file}"
        fi
    fi

done <"${todo_list}"

echo "========== RESULT ========="
cat "${output_file}"
