#!/usr/bin/env bash

here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $here || exit

echo "alias koshu-test='$here/src/koshu.sh test -f $here/koshufile'"
echo "alias koshu-watch='watch -p \"**/*\" -c \"$here/src/koshu.sh test -f $here/koshufile\"'"
echo "alias koshu-dev='$here/src/koshu.sh'"
echo
echo "# Run this command to configure your shell:"
echo "# eval \"\$(./env.sh)\""
