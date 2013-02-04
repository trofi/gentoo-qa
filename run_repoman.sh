#!/bin/bash

${PYTHON:-python} "$(type -p repoman)" full -d > repoman-QA-`date +%F-%T`.log
