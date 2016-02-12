#!/bin/bash

# script to get list of installed overlay packages not in a world set

overlay_name=${1-haskell}
{
  # get installed packages
  eix --only-names --installed         --in-overlay ${overlay_name}
  # get installed @world packages
  eix --only-names --installed --world --in-overlay ${overlay_name}

# print only unique (aka not installed)
} | sort | uniq -u
