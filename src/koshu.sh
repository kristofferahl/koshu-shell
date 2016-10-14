#!/usr/bin/env bash

# init

set -e
trap koshu_exit INT TERM EXIT

here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# parameters

koshu_param_tasklist=()
koshu_param_taskfile='./koshufile'
koshu_param_silent=false

# koshufile aliases

shopt -s expand_aliases
alias task="function"
alias depends_on="koshu_depends_on"

alias verbose="koshu_log_verbose"
alias success="koshu_log_success"
alias info="koshu_log_info"
alias warn="koshu_log_warn"
alias error="koshu_log_error"

# internals

koshu_exiting=false
koshu_available_tasks=()
koshu_executed_tasks=()

function koshu_version () {
  info "Koshu v. 0.3.0"
}

function koshu_logo () {
  echo -e "${KOSHU_RESET}${KOSHU_BLUE} _  __         _
| |/ /___  ___| |__  _   _
| ' // _ \/ __| '_ \| | | |
| . \ (_) \__ \ | | | |_| |
|_|\_\___/|___/_| |_|\__,_|
======================================================
Koshu - The honey flavoured shell task automation tool
======================================================${KOSHU_RESET}
"
}

function koshu_usage () {
  koshu_version
  info "Usage: ./koshu.sh [<command|task>] [--<option>]"
}

function koshu_help () {
  koshu_logo
  koshu_usage
  verbose
  verbose "  The first argument must be a <command> or a <task> where"
  verbose "  the value is the name of a task you wish to execute"
  verbose "  or the name of a koshu command."
  verbose
  verbose "  commands:"
  verbose "    init                        Initialized koshu"
  verbose "    help                        Displays this help message"
  verbose "    version                     Displays the version number"
  verbose "    run <task1> <task2>         Run task"
  verbose
  verbose "  options:"
  verbose "    -s, --silent                Suppress output from koshu"
  verbose "    -f <file>, --file <file>    Specifies the path to the koshufile (default ./koshufile)"
  verbose
  verbose "  examples:"
  verbose "    ./koshu.sh compile"
  verbose "    ./koshu.sh test:all --file ./path/to/koshufile"
  verbose
}

KOSHU_BLUE="\033[1;94m"
KOSHU_GREEN="\033[1;92m"
KOSHU_RED="\033[0;91m"
KOSHU_YELLOW="\033[0;93m"
KOSHU_GRAY="\033[0;90m"
KOSHU_RESET="\033[0m"

function koshu_log_verbose() { [[ $koshu_param_silent = true ]] || echo -e "${KOSHU_RESET}${KOSHU_GRAY}koshu: ${1}${KOSHU_RESET}"; }
function koshu_log_success() { [[ $koshu_param_silent = true ]] || echo -e "${KOSHU_RESET}${KOSHU_GREEN}koshu: ${1}${KOSHU_RESET}"; }
function koshu_log_info() { [[ $koshu_param_silent = true ]] || echo -e "${KOSHU_RESET}${KOSHU_BLUE}koshu: ${1}${KOSHU_RESET}"; }
function koshu_log_warn() { [[ $koshu_param_silent = true ]] || echo -e "${KOSHU_RESET}${KOSHU_YELLOW}koshu: ${1}${KOSHU_RESET}"; }
function koshu_log_error() { [[ $koshu_param_silent = true ]] || echo -e "${KOSHU_RESET}${KOSHU_RED}koshu: ${1}${KOSHU_RESET}"; }

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

function koshu_init () {
  verbose 'Initializing koshu'
  if [[ ! -f "$koshu_param_taskfile" ]]; then
    verbose "Creating koshufile ($koshu_param_taskfile)"

    echo "#!/usr/bin/env bash

task default {
  echo 'Hello world!'
}
" > "$koshu_param_taskfile"
  else
    verbose "Koshufile already exists ($koshu_param_taskfile)"
  fi
}

function koshu_run () {
  local tasklist=("${!1}")

  # ensure koshufile is located in the context of the current directory
  cd "$( pwd )"
  if [[ ! -f "$koshu_param_taskfile" ]]; then
    koshu_exit "'$koshu_param_taskfile' is not a valid path for koshufile" 1
  fi

  # ensure here is set properly before sourcing koshufile
  here="$( cd "$( dirname "$koshu_param_taskfile" )" && pwd )"
  cd $here

  # import koshufile
  chmod +xrw "$koshu_param_taskfile"
  . "$koshu_param_taskfile" --source-only

  # variable must be set after importing koshufile
  koshu_functions=($(declare -F | sed 's/declare -f //g'))

  for f in ${koshu_functions[@]}; do
    if [[ $f != koshu_* ]]; then
      koshu_available_tasks+=("$f")
    fi
  done

  for t in ${tasklist[@]}; do
    if [[ "$(koshu_array_contains $t ${koshu_available_tasks[@]})" = "true" ]]; then
      koshu_exec_task $t
    else
      koshu_usage
      info "Run \"koshu help\" for more info."
      koshu_exit "Task '$t' is not defined. Available tasks: $(koshu_array_print koshu_available_tasks[@])" 1
    fi
  done
}

parser_arguments=("$@")
parser_commands=()
parser_options=()
parser_index=0

for arg in ${parser_arguments[*]}; do
  if [[ "${arg:0:1}" = "-" ]]; then
    if [[ "${arg:1:1}" != "-" ]]; then
      key="${arg:1}"
    else
      key="${arg:2}"
    fi

    value=${parser_arguments[parser_index+1]:-true}
    if [[ "${value:0:1}" = "-" ]]; then
      value=true
    fi

    parser_options+=("$key"="$value")
  else
    if [[ ${#parser_options[*]} -eq 0 ]]; then
      parser_commands+=("$arg")
    fi
  fi
  (( parser_index++ ))
done

for kvp in "${parser_options[@]}"; do
  option=(${kvp//=/ }[0])
  value=${kvp#*=}

  case "$option" in
    "f" | "file" )
      koshu_param_taskfile=$value
      ;;
    "s" | "silent" )
      koshu_param_silent=true
      ;;
    * )
      koshu_usage >&2
      koshu_exit "Invalid option '$option'" 1
      ;;
  esac
done

for c in "${parser_commands[@]}"; do
  case "$c" in
    "help" )
      koshu_help
      koshu_exit '' 0
      ;;
    "version" )
      koshu_version
      koshu_exit '' 0
      ;;
    "init" )
      koshu_init
      koshu_exit 'Finished initializing koshu' 0
      ;;
    "run" )
      koshu_param_tasklist=("${parser_commands[*]:1}")
      ;;
    * ) # Unknown commands must map to task names
      koshu_param_tasklist+=("$c")
      ;;
  esac
done

if [[ "${#koshu_param_tasklist[*]}" -lt 1 ]]; then
  koshu_param_tasklist=('default')
fi

koshu_run koshu_param_tasklist[@]
koshu_exit "Finished executing tasks ($(koshu_array_print koshu_executed_tasks[@] ' %s '))" 0
