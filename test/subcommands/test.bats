#!/usr/bin/env bats

@test "executes subcommand init with file option specified" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" init --file "$BATS_TEST_DIRNAME/koshufile-init"

  [ $status -eq 0 ]
}

@test "executes subcommand help" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" help

  [ $status -eq 0 ]
}

@test "executes subcommand version" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" version

  [ $status -eq 0 ]
}

@test "executes subcommand run with taskname init, help and version" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" run init help version --silent --file "$BATS_TEST_DIRNAME/koshufile"

  [ $status -eq 0 ]
  [  $(expr "${lines[0]}" : "Initializing...") -ne 0 ]
  [  $(expr "${lines[1]}" : "Printing help...") -ne 0 ]
  [  $(expr "${lines[2]}" : "Printing version...") -ne 0 ]
}
