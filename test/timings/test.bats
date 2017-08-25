#!/usr/bin/env bats

@test "prints task execution time" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" default --file "$BATS_TEST_DIRNAME/koshufile"

  [ $status -eq 0 ]
  if [[  "${lines[5]}" != *"Finished setup ( 1s )"* ]]; then exit 1; fi
  if [[  "${lines[7]}" != *"Finished compile ( 2s )"* ]]; then exit 1; fi
  if [[  "${lines[9]}" != *"Finished test ( 3s )"* ]]; then exit 1; fi
}
