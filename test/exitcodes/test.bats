#!/usr/bin/env bats

@test "exits with code 123" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" default --file "$BATS_TEST_DIRNAME/koshufile"

  [ $status -eq 123 ]
}

@test "exits with error message" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" default --file "$BATS_TEST_DIRNAME/koshufile"

  [[ "$output" = *"Exiting with code 123"* ]]
}
