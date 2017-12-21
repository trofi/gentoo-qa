#!/bin/bash

${PYTHON:-python} "$(type -p repoman)" full \
    --quiet -d -e y --ignore-masks > repoman-QA-`date +%F-%T`.log
