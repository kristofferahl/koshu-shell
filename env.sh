#!/usr/bin/env bash

here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $here || exit

echo "alias test='$here/src/koshu.sh test --file $here/koshufile'"
echo "alias koshudev='$here/src/koshu.sh'"
echo "# Run this command to configure your shell:"
echo "# eval \"\$(./env.sh)\""
