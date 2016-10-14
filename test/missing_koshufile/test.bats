#!/usr/bin/env bats

@test "missing koshufile exits with code 1" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" default --file "$BATS_TEST_DIRNAME/koshufile"

  [ $status -eq 1 ]
}
