#!/bin/bash

# checks for redundancy of type:
#    <herd>some-herd</herd>
#    <email>some-herd@gentoo.org</email>

find . -type f -name 'metadata.xml' | while read e
do
    while read l
    do
        if [[ $l == *"<herd>"*"</herd>"* ]]; then
            herd=$l
            herd=${herd#*<herd>}
            herd=${herd%</herd>*}
            mail_string="<email>${herd}@gentoo.org</email>"
            fgrep "${mail_string}" "$e"
        fi
    done < "$e"
done
