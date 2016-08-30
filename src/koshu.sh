#!/usr/bin/env bash

# init

set -e
trap exit_with_message INT TERM EXIT

here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $here

# parameters

param_taskname=${1:-'default'}

# koshufile aliases

shopt -s expand_aliases
alias task="function"

# import koshufile

chmod +xrw ./koshufile
. ./koshufile --source-only

# variables (must be declared after import)

exiting=false
tasks=($(declare -F | sed 's/declare -f //g'))
executed_tasks=()

# internals

BLUE="\033[1;94m"
GREEN="\033[1;92m"
RED="\033[0;91m"
YELLOW="\033[0;93m"
CYAN="\033[0;96m"
RESET="\033[0m"

function success() { echo -e "${RESET}${GREEN}koshu: ${1}${RESET}"; }
function info() { echo -e "${RESET}${BLUE}koshu: ${1}${RESET}"; }
function warn() { echo -e "${RESET}${YELLOW}koshu: ${1}${RESET}"; }
function error() { echo -e "${RESET}${RED}koshu: ${1}${RESET}"; }

function exit_with_message () {
  local exitcode=${2:-$?}

  if [[ $exiting = false ]]; then
    local msg=${1:-""}

    if [[ $exitcode = 0 ]]; then
      if [[ "$msg" != "" ]]; then
        success "$msg"
      fi
      success "Exit code: $exitcode"
    else
      error "${msg:-An unhandled error occured.}"
      error "Exit code: $exitcode"
    fi
  fi

  exiting=true
  exit $exitcode
}

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

  info "Starting $task_name"
  local start_time=`date +%s`

  $task_name

  local end_time=`date +%s`
  success "Finished executing $task_name ( `expr $end_time - $start_time`s )"
  cd $here

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

  exit_with_message "Finished executing tasks ($(array_print executed_tasks[@] ' %s '))"
else
  exit_with_message "Task '$param_taskname' is not defined. Available tasks: $(array_print tasks[@])" 1
fi
