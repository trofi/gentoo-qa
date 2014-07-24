#!/bin/bash

find . -type f -name '*.ebuild' | while read e
do
    while read l
    do
        if [[ $l == 'DESCRIPTION='*'."' ]]; then
            echo "$e: fixing '.' in description"
            sed -i -e '/^DESCRIPTION=/ { s/."$/"/ }' "$e"
        fi
    done < "$e"
done
