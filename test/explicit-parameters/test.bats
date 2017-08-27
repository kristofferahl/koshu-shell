#!/usr/bin/env bats

@test "allows all parameters" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" all --silent --file "$BATS_TEST_DIRNAME/koshufile" -p p1=a -p p2=b -p p3=c

  [ $status -eq 0 ]
  [ "$output" == "a.b.c." ]
}

@test "allows single parameter" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" single --silent --file "$BATS_TEST_DIRNAME/koshufile" -p p1=a -p p2=b -p p3=c

  [ $status -eq 0 ]
  [ "$output" == "default value.b.default value." ]
}

@test "allows only parameters for outer most task" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" outer --silent --file "$BATS_TEST_DIRNAME/koshufile" -p p1=a -p p2=b -p p3=c

  [ $status -eq 0 ]
  [ "$output" == "a.default value.default value." ]
}
