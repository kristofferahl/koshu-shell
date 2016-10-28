#!/usr/bin/env bats

@test "parses -p and --param correctly" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" default --silent --file "$BATS_TEST_DIRNAME/koshufile" -p p1=a --param p2=b

  [ $status -eq 0 ]
  [ "$output" == "a.b.default value." ]
}

@test "parses parameters with spaces correctly" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" default --silent --file "$BATS_TEST_DIRNAME/koshufile" -p p1='a with spaces' -p p2="b with spaces" -p p3=c with spaces

  [ $status -eq 0 ]
  [ "$output" == "a with spaces.b with spaces.c." ] # p3 should be = c
}

@test "handles parameters with no name correctly" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" default --silent --file "$BATS_TEST_DIRNAME/koshufile" -p =x --param =x -p p1=a -p p2=b -p p3=c

  [ $status -eq 0 ]
  [ "$output" == "a.b.c." ]
}

@test "handles parameters with only equals sign" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" default --silent --file "$BATS_TEST_DIRNAME/koshufile" -p = --param = -p p1=a -p p2=b -p p3=c

  [ $status -eq 0 ]
  [ "$output" == "a.b.c." ]
}

@test "does not override parameters already set" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" default --silent --file "$BATS_TEST_DIRNAME/koshufile" -p p1=a -p p1=b

  [ $status -eq 0 ]
  [ "$output" == "a.default value.default value." ]
}
