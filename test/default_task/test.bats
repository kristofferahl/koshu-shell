#!/usr/bin/env bats

@test "default task is executed when no tasks are specified" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" --file "$BATS_TEST_DIRNAME/koshufile"

  [ $status -eq 0 ]
}
