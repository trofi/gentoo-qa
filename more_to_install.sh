#!/bin/bash

# script to get list of not-installed-yet packages
# from specified overlay

overlay_name=${1-haskell}
{
  # get all packages
  eix --only-names --non-masked             --in-overlay ${overlay_name}
  # get installed packages
  eix --only-names --non-masked --installed --in-overlay ${overlay_name}

  # --non-masked should have done it but does not for some reason.
  # get masked packages, avoid installing them
  EROOT=$(portageq envvar EROOT)
  REPO_ROOT=$(portageq get_repo_path "${EROOT}" ${overlay_name})
  sed -e 's/\s*#.*//g' "$REPO_ROOT"/profiles/package.mask | grep -v '^$'
  sed -e 's/\s*#.*//g' "$REPO_ROOT"/profiles/package.mask | grep -v '^$'
# print only unique (aka not installed)
} | sort | uniq -u
