#!/usr/bin/env bats

@test "lists available tasks and exits" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" tasks --file "$BATS_TEST_DIRNAME/koshufile"

  [ $status -eq 0 ]
  [  $(expr "${lines[1]}" : "  - first") -ne 0 ]
  [  $(expr "${lines[2]}" : "  - second") -ne 0 ]
  [  $(expr "${lines[3]}" : "  - third") -ne 0 ]
}
