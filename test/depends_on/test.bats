#!/usr/bin/env bats

@test "executes tasks in expected order" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" default --file "$BATS_TEST_DIRNAME/koshufile"

  [ $status -eq 0 ]
  [  $(expr "${lines[4]}" : "Setting up...") -ne 0 ]
  [  $(expr "${lines[6]}" : "Compiling...") -ne 0 ]
  [  $(expr "${lines[8]}" : "Testing...") -ne 0 ]
}

@test "executes tasks at most once" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" run setup setup test test default --silent --file "$BATS_TEST_DIRNAME/koshufile"

  [ $status -eq 0 ]
  [  $(expr "${lines[0]}" : "Setting up...") -ne 0 ]
  [  $(expr "${lines[1]}" : "Compiling...") -ne 0 ]
  [  $(expr "${lines[2]}" : "Testing...") -ne 0 ]
}
