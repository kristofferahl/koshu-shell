#!/usr/bin/env bats

@test "here is set before sourcing koshufile" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" --silent --file "$BATS_TEST_DIRNAME/koshufile"

  [ $status -eq 0 ]
  [  $(expr "${lines[0]}" : "sourced: $BATS_TEST_DIRNAME") -ne 0 ]
}

@test "tasks are executed in the context of koshufile (here)" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" --silent --file "$BATS_TEST_DIRNAME/koshufile"

  [ $status -eq 0 ]
  [  $(expr "${lines[1]}" : "task: $BATS_TEST_DIRNAME") -ne 0 ]
}

@test "tasks can override here" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" override --silent --file "$BATS_TEST_DIRNAME/koshufile"

  [ $status -eq 0 ]
  [  $(expr "${lines[1]}" : "override: ./somewhere") -ne 0 ]
}

@test "here is reset before executing a task" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" reset --silent --file "$BATS_TEST_DIRNAME/koshufile"

  [ $status -eq 0 ]
  [  $(expr "${lines[2]}" : "reset: $BATS_TEST_DIRNAME") -ne 0 ]
}
