#!/usr/bin/env bats

@test "does not log koshu messages" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" default --file "$BATS_TEST_DIRNAME/koshufile" --silent

  [[ "$output" == "Yohooo" ]]
}
