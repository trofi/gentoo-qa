#!/bin/bash

# script to get list of not-installed-yet packages
# from specified overlay

overlay_name=${1-haskell}
{
  # get all packages
  eix --only-names             --in-overlay ${overlay_name}
  # get installed packages
  eix --only-names --installed --in-overlay ${overlay_name}

# print only unique (aka not installed)
} | sort | uniq -u
