#!/usr/bin/env bats

@test "parses -e and --env correctly" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" default --silent --file "$BATS_TEST_DIRNAME/koshufile" -e TEST_ENV_1=a --env TEST_ENV_2=b

  [ $status -eq 0 ]
  [  $(expr "${lines[0]}" : "TEST_ENV_1=a") -ne 0 ]
  [  $(expr "${lines[1]}" : "TEST_ENV_2=b") -ne 0 ]
}

@test "parses envrionment parameters with spaces correctly" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" default --silent --file "$BATS_TEST_DIRNAME/koshufile" -e TEST_ENV_1='a with spaces' -e TEST_ENV_2="b with spaces" -e TEST_ENV_3=c with spaces

  [ $status -eq 0 ]
  [  $(expr "${lines[0]}" : "TEST_ENV_1=a with spaces") -ne 0 ]
  [  $(expr "${lines[1]}" : "TEST_ENV_2=b with spaces") -ne 0 ]
  [  $(expr "${lines[2]}" : "TEST_ENV_3=c") -ne 0 ]
}

@test "handles envrionment parameters with no name correctly" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" default --silent --file "$BATS_TEST_DIRNAME/koshufile" -e =x --env =x -e TEST_ENV_1=a --env TEST_ENV_2=b

  [ $status -eq 0 ]
  [  $(expr "${lines[0]}" : "TEST_ENV_1=a") -ne 0 ]
  [  $(expr "${lines[1]}" : "TEST_ENV_2=b") -ne 0 ]
}

@test "handles envrionment parameters with only equals sign" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" default --silent --file "$BATS_TEST_DIRNAME/koshufile" -e = --env = -e TEST_ENV_1=a --env TEST_ENV_2=b

  [ $status -eq 0 ]
  [  $(expr "${lines[0]}" : "TEST_ENV_1=a") -ne 0 ]
  [  $(expr "${lines[1]}" : "TEST_ENV_2=b") -ne 0 ]
}

@test "does not override environment variables already set" {
  run "$KOSHU_SOURCE_DIR/koshu.sh" default --silent --file "$BATS_TEST_DIRNAME/koshufile" -e TEST_ENV_1=a --env TEST_ENV_1=b

  [ $status -eq 0 ]
  [  $(expr "${lines[0]}" : "TEST_ENV_1=a") -ne 0 ]
}
