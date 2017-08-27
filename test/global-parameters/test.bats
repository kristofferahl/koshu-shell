#!/usr/bin/env bats

@test "allows global parameters only" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" global_only --silent --file "$BATS_TEST_DIRNAME/koshufile" -p p1=a -p p2=b -p p3=c

  [ $status -eq 0 ]
  [ "$output" == "a.b.default value." ]
}

@test "allows global and specific parameters" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" global_and_specific --silent --file "$BATS_TEST_DIRNAME/koshufile" -p p1=a -p p2=b -p p3=c

  [ $status -eq 0 ]
  [ "$output" == "a.b.c." ]
}

@test "allows specific parameters only" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" specific_only --silent --file "$BATS_TEST_DIRNAME/koshufile" -p p4=d

  [ $status -eq 0 ]
  [ "$output" == "default value.default value.default value.d." ]
}
