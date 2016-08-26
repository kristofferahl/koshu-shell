#!/usr/bin/env bash

# init

here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $here
clear

# parameters

param_taskname=${1:-'default'}

# koshufile aliases

shopt -s expand_aliases
alias task="function"

# import koshufile

chmod +xrw ./koshufile
. ./koshufile --source-only

# variables (must be declared after import)

tasks=($(declare -F | sed 's/declare -f //g'))
executed_tasks=()

# internals

BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[0;31m"
RESET="\033[0m"

pinfo() { echo -e "${BLUE}koshu: ${1}${RESET}"; }
psuccess() { echo -e "${GREEN}koshu: ${1}${RESET}"; }
perror() { echo -e "${RED}koshu: ${1}${RESET}"; }

function array_print () {
  local arr=("${!1}")
  local f=${2:-'\n  - %s'}
  printf "$f" "${arr[@]}"
}

function array_contains () {
  local e
  local r=false
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && r=true; done
  echo $r
}

function exec_task () {
  local task_name=${1}

  pinfo "Starting $task_name"
  $task_name
  psuccess "Finished executing $task_name"

  executed_tasks+=("$task_name")
}

function depends_on () {
  local task_name=${1}
  local executed=$(array_contains $task_name ${executed_tasks[@]})
  if [[ $executed = false ]]; then
    exec_task $task_name
  fi
}

taskfound=$(array_contains $param_taskname ${tasks[@]})
if [[ $taskfound = "true" ]]; then
  exec_task $param_taskname

  psuccess "Finished executing tasks ($(array_print executed_tasks[@] ' %s '))"
else
  perror "Task '$param_taskname' is not defined. Available tasks: $(array_print tasks[@])"
fi
