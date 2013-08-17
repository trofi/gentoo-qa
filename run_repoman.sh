#!/bin/bash

${PYTHON:-python} "$(type -p repoman)" manifest
${PYTHON:-python} "$(type -p repoman)" full -d --ignore-masks > repoman-QA-`date +%F-%T`.log
