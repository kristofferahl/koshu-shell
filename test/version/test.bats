#!/usr/bin/env bats

@test "prints the current version" {
  #expected="$(cat package.json | jq -r .version)"
  expected="$(cat package.json | grep version | head -1 | awk -F: '{ print $2 }' | sed 's/[",]//g' | tr -d '[[:space:]]')"

  run "$KOSHU_SOURCE_DIR/koshu.sh" printversion --silent --file "$BATS_TEST_DIRNAME/koshufile"

  [ $status -eq 0 ]
  [ $(expr "${lines[0]}" : "$expected") -ne 0 ]
}
