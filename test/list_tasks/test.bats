#!/usr/bin/env bats

@test "lists available tasks and exits" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" tasks --file "$BATS_TEST_DIRNAME/koshufile"

  [ $status -eq 0 ]
  [[ "${lines[1]}" == *"- first"* ]]
  [[ "${lines[2]}" == *"- second"* ]]
  [[ "${lines[3]}" == *"- third"* ]]
}
