#!/usr/bin/env bash

# init

set -e
trap koshu_exit INT TERM EXIT

here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $here

# parameters

koshu_param_taskname=${BASH_ARGV:-'default'}
koshu_param_taskfile='./koshufile'

# koshufile aliases

shopt -s expand_aliases
alias task="function"
alias depends_on="koshu_depends_on"

alias log="koshu_log_verbose"
alias success="koshu_log_success"
alias info="koshu_log_info"
alias warn="koshu_log_warn"
alias error="koshu_log_error"

# internals

function koshu_version () {
  info "Koshu v. 0.1.0"
}

function koshu_usage () {
  koshu_version
  info "Usage: ./koshu.sh [-h] [-v] [...] <task>"
}

function koshu_help () {
  koshu_usage
  log
  log "  <task> is the name of the task you wish to execute and"
  log "  is always the last argument."
  log
  log "  -h, --help     Displays this help message"
  log "  -v, --version  Displays the version number"
  log "  -f <koshufile>, --file <koshufile>  Specifies the path to the koshufile (default ./koshufile)"
  log
  log "  examples:"
  log
  log "    ./koshu.sh compile"
  log "    ./koshu.sh --file ./path/to/koshufile copy:all"
  log
}

KOSHU_BLUE="\033[1;94m"
KOSHU_GREEN="\033[1;92m"
KOSHU_RED="\033[0;91m"
KOSHU_YELLOW="\033[0;93m"
KOSHU_GRAY="\033[0;90m"
KOSHU_RESET="\033[0m"

function koshu_log_verbose() { echo -e "${KOSHU_RESET}${KOSHU_GRAY}koshu: ${1}${KOSHU_RESET}"; }
function koshu_log_success() { echo -e "${KOSHU_RESET}${KOSHU_GREEN}koshu: ${1}${KOSHU_RESET}"; }
function koshu_log_info() { echo -e "${KOSHU_RESET}${KOSHU_BLUE}koshu: ${1}${KOSHU_RESET}"; }
function koshu_log_warn() { echo -e "${KOSHU_RESET}${KOSHU_YELLOW}koshu: ${1}${KOSHU_RESET}"; }
function koshu_log_error() { echo -e "${KOSHU_RESET}${KOSHU_RED}koshu: ${1}${KOSHU_RESET}"; }

function koshu_exit () {
  local exitcode=${2:-$?}

  if [[ $koshu_exiting = false ]]; then
    local msg=${1:-""}

    if [[ $exitcode = 0 ]]; then
      if [[ "$msg" != "" ]]; then
        success "$msg"
      fi
    else
      error "${msg:-An unhandled error occured.}"
      error "Exit code: $exitcode"
    fi
  fi

  koshu_exiting=true
  exit $exitcode
}

function koshu_array_print () {
  local arr=("${!1}")
  local f=${2:-'\n  - %s'}
  printf "$f" "${arr[@]}"
}

function koshu_array_contains () {
  local e
  local r=false
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && r=true; done
  echo $r
}

function koshu_array_indexof () {
  local arr=$2
  local e
  local r=-1
  for i in "${!arr[@]}"; do [[ "${arr[$i]}" == "$1" ]] && r=$i; done
  echo $r
}

function koshu_exec_task () {
  local task_name=${1}

  info "Starting $task_name"
  local start_time=`date +%s`

  $task_name

  local end_time=`date +%s`
  success "Finished executing $task_name ( `expr $end_time - $start_time`s )"
  cd $here

  koshu_executed_tasks+=("$task_name")
}

function koshu_depends_on () {
  local task_name=${1}
  local executed=$(koshu_array_contains $task_name ${koshu_executed_tasks[@]})
  if [[ $executed = false ]]; then
    koshu_exec_task $task_name
  fi
}

function koshu_expand_path() {
  { cd "$(dirname "$1")" 2>/dev/null
    local dirname="$PWD"
    cd "$OLDPWD"
    echo "$dirname/$(basename "$1")"
  } || echo "$1"
}

function koshu_set_koshufile() {
  local index_of_f=$(koshu_array_indexof '-f' ${koshu_arguments[@]})
  local index_of_file=$(koshu_array_indexof '--file' ${koshu_arguments[@]})

  if [[ $index_of_f > -1 ]]; then
    local value_of_f=${koshu_arguments[$index_of_f + 1]}
    if [[ -n "$value_of_f" ]]; then
      koshu_param_taskfile=$value_of_f
    fi
  fi

  if [[ $index_of_file > -1 ]]; then
    local value_of_file=${koshu_arguments[$index_of_file + 1]}
    if [[ -n "$value_of_file" ]]; then
      koshu_param_taskfile=$value_of_file
    fi
  fi

  if [[ ! -f "$koshu_param_taskfile" ]]; then
    koshu_exit "'$(koshu_expand_path "$koshu_param_taskfile")' is not a valid path for koshufile" 1
  fi
}

koshu_arguments=()
koshu_options=()

for arg in "$@"; do
  if [ "${arg:0:1}" = "-" ]; then
    if [ "${arg:1:1}" = "-" ]; then
      koshu_options[${#koshu_options[*]}]="${arg:2}"
    else
      index=1
      while option="${arg:$index:1}"; do
        [ -n "$option" ] || break
        koshu_options[${#koshu_options[*]}]="$option"
        let index+=1
      done
    fi
  fi
  koshu_arguments[${#koshu_arguments[*]}]="$arg"
done

for option in "${koshu_options[@]}"; do
  case "$option" in
  "h" | "help" )
    koshu_help
    koshu_exit '' 0
    ;;
  "v" | "version" )
    koshu_version
    koshu_exit '' 0
    ;;
  "f" | "file" )
    koshu_set_koshufile
    ;;
  * )
    koshu_usage >&2
    koshu_exit "Invalid option '$option'" 1
    ;;
  esac
done

# import koshufile

chmod +xrw "$koshu_param_taskfile"
. "$koshu_param_taskfile" --source-only

# variables (must be declared after import)

koshu_exiting=false
koshu_functions=($(declare -F | sed 's/declare -f //g'))
koshu_available_tasks=()
koshu_executed_tasks=()

for f in ${koshu_functions[@]}; do
  if [[ $f != koshu_* ]]; then
    koshu_available_tasks+=("$f")
  fi
done

if [[ "$(koshu_array_contains $koshu_param_taskname ${koshu_available_tasks[@]})" = "true" ]]; then
  koshu_exec_task $koshu_param_taskname
  koshu_exit "Finished executing tasks ($(koshu_array_print koshu_executed_tasks[@] ' %s '))"
else
  koshu_exit "Task '$koshu_param_taskname' is not defined. Available tasks: $(koshu_array_print koshu_available_tasks[@])" 1
fi
