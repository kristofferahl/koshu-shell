here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $here

echo "alias test='$here/src/koshu.sh test --file ./../koshufile'"
echo "# Run this command to configure your shell:"
echo "# eval \"\$(./env.sh)\""
