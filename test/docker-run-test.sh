#!/usr/bin/env bash

# Prepare tests
cd /bats || exit
./install.sh /usr/local

# Run tests
cd /koshu-shell || exit
here="$(pwd)"
echo "$here"
$here/src/koshu.sh test --file $here/koshufile
