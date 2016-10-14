#!/usr/bin/env bats

@test "executes tasks in expected order" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" default --file "$BATS_TEST_DIRNAME/koshufile"

  [ $status -eq 0 ]
  [  $(expr "${lines[4]}" : "Setting up...") -ne 0 ]
  [  $(expr "${lines[6]}" : "Compiling...") -ne 0 ]
  [  $(expr "${lines[8]}" : "Testing...") -ne 0 ]
}
