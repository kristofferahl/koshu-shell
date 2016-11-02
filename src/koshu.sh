#!/usr/bin/env bash

# init

set -e
trap koshu_exit INT TERM EXIT

# parameters

declare -a koshu_param_tasklist=()
declare koshu_param_taskfile='./koshufile'
declare koshu_param_silent=false

# koshufile aliases

shopt -s expand_aliases

alias task="function"
alias param="koshu_set_param"
alias depends_on="koshu_exec_task"
alias verbose="koshu_log_verbose"
alias success="koshu_log_success"
alias info="koshu_log_info"
alias warn="koshu_log_warn"
alias error="koshu_log_error"

# internals

declare -r koshu_version='0.5.4'
declare -r koshu_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
declare koshu_exiting=false
declare -a koshu_available_tasks=()
declare -a koshu_executed_tasks=()
declare -a koshu_params=()
declare -a koshu_envs=()
declare here

function koshu_version () {
  info "Koshu v. $koshu_version"
}

function koshu_logo () {
  echo -e "${koshu_reset}${koshu_blue} _  __         _
| |/ /___  ___| |__  _   _
| ' // _ \/ __| '_ \| | | |
| . \ (_) \__ \ | | | |_| |
|_|\_\___/|___/_| |_|\__,_|
======================================================
Koshu - The honey flavoured task automation tool
======================================================${koshu_reset}
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
  verbose "    tasks                       Lists available tasks"
  verbose "    run <task1> <task2>         Run task"
  verbose
  verbose "  options:"
  verbose "    -s, --silent                Suppress output from koshu"
  verbose "    -f <file>, --file <file>    Specifies the path to the koshufile (default ./koshufile)"
  verbose "    -p <name=value>, --param <name=value>    Sets variable before tasks are executed"
  verbose "    -e <name=value>, --env <name=value>    Sets environment variable before tasks are executed"
  verbose
  verbose "  examples:"
  verbose "    ./koshu.sh compile"
  verbose "    ./koshu.sh test:all --file ./path/to/koshufile"
  verbose
}

declare -r koshu_blue="\033[1;94m"
declare -r koshu_green="\033[1;92m"
declare -r koshu_red="\033[0;91m"
declare -r koshu_yellow="\033[0;93m"
declare -r koshu_gray="\033[0;90m"
declare -r koshu_reset="\033[0m"

function koshu_log_verbose() { [[ $koshu_param_silent = true ]] || echo -e "${koshu_reset}${koshu_gray}koshu: ${1}${koshu_reset}"; }
function koshu_log_success() { [[ $koshu_param_silent = true ]] || echo -e "${koshu_reset}${koshu_green}koshu: ${1}${koshu_reset}"; }
function koshu_log_info() { [[ $koshu_param_silent = true ]] || echo -e "${koshu_reset}${koshu_blue}koshu: ${1}${koshu_reset}"; }
function koshu_log_warn() { [[ $koshu_param_silent = true ]] || echo -e "${koshu_reset}${koshu_yellow}koshu: ${1}${koshu_reset}"; }
function koshu_log_error() { [[ $koshu_param_silent = true ]] || echo -e "${koshu_reset}${koshu_red}koshu: ${1}${koshu_reset}"; }

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
  local executed=$(koshu_array_contains $task_name ${koshu_executed_tasks[@]})
  if [[ $executed = false ]]; then
    # ensure here is set properly before executing task
    koshu_set_here

    info "Starting $task_name"
    local start_time=`date +%s`

    $task_name

    local end_time=`date +%s`
    success "Finished executing $task_name ( `expr $end_time - $start_time`s )"

    # ensure here is reset properly after executing task
    koshu_set_here

    koshu_executed_tasks+=("$task_name")
  fi
}

function koshu_set_here () {
  here="$( cd "$( dirname "$koshu_param_taskfile" )" && pwd )"
  cd $here
}

function koshu_expand_path () {
  { cd "$(dirname "$1")" 2>/dev/null
    local dirname="$PWD"
    cd "$OLDPWD"
    echo "$dirname/$(basename "$1")"
  } || echo "$1"
}

function koshu_set_param () {
  local value="$1"
  local param_name=(${value//=/ }[0])
  local param_value="${value#*=}"

  if [ "$param_name" != "" ] && [ "$param_name" != "$param_value[0]" ]; then
    if [ "$(koshu_array_contains $param_name ${koshu_params[@]})" != "true" ]; then
      printf -v "${param_name}" '%s' "${param_value}"
      koshu_params+=("$param_name")
    fi
  fi
}

function koshu_set_env () {
  local value="$1"
  local env_name=(${value//=/ }[0])
  local env_value="${value#*=}"

  if [ "$env_name" != "" ] && [ "$env_name" != "$env_value[0]" ]; then
    if [ "$(koshu_array_contains $env_name ${koshu_envs[@]})" != "true" ]; then
      eval "export $env_name'=${env_value}'"
      koshu_envs+=("$env_name")
    fi
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

function koshu_bootstrap () {
  # ensure koshufile is located in the context of the current directory
  cd "$( pwd )"
  if [[ ! -f "$koshu_param_taskfile" ]]; then
    koshu_exit "'$koshu_param_taskfile' is not a valid path for koshufile" 1
  fi

  # expand path to koshufile
  koshu_param_taskfile=$(koshu_expand_path "$koshu_param_taskfile")

  # ensure here is set properly before sourcing koshufile
  koshu_set_here

  # import koshufile
  chmod +xrw "./koshufile"
  . "./koshufile" --source-only

  # variable must be set after importing koshufile
  koshu_functions=($(declare -F | sed 's/declare -f //g'))

  for f in ${koshu_functions[@]}; do
    if [[ $f != koshu_* ]]; then
      koshu_available_tasks+=("$f")
    fi
  done
}

function koshu_run () {
  local tasklist=("${!1}")

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

declare -ar parser_arguments=("$@")
declare -a parser_commands=()
declare -a parser_options=()
declare -i parser_index=0
declare parser_argument
declare parser_option
declare parser_command
declare parser_key
declare parser_value

for parser_argument in "${parser_arguments[@]}"; do
  if [[ "${parser_argument:0:1}" = "-" ]]; then
    if [[ "${parser_argument:1:1}" != "-" ]]; then
      parser_key="${parser_argument:1}"
    else
      parser_key="${parser_argument:2}"
    fi

    parser_value=${parser_arguments[parser_index+1]:-true}
    if [[ "${parser_value:0:1}" = "-" ]]; then
      parser_value=true
    fi

    parser_options+=("$parser_key=$parser_value")
  else
    if [[ ${#parser_options[*]} -eq 0 ]]; then
      parser_commands+=("$parser_argument")
    fi
  fi
  (( parser_index+=1 ))
done

for parser_option in "${parser_options[@]}"; do
  if [[ "$parser_option" =~ '^([^=]+)=(.*)$' ]]; then
    parser_key="${BASH_REMATCH[1]}"
    parser_value="${BASH_REMATCH[2]}"
  else
    parser_key=(${parser_option//=/ }[0])
    parser_value=${parser_option#*=}
  fi

  case "$parser_key" in
    "f" | "file" )
      koshu_param_taskfile="$parser_value"
      ;;
    "p" | "param" )
      koshu_set_param "$parser_value"
      ;;
    "e" | "env" )
      koshu_set_env "$parser_value"
      ;;
    "s" | "silent" )
      koshu_param_silent=true
      ;;
    * )
      koshu_usage >&2
      koshu_exit "Invalid option '$parser_key'" 1
      ;;
  esac
done

declare parser_commands_continue=true
for parser_command in "${parser_commands[@]}"; do
  if [[ $parser_commands_continue == true ]]; then
    case "$parser_command" in
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
      "tasks" )
        koshu_bootstrap
        koshu_exit "Available tasks: $(koshu_array_print koshu_available_tasks[@])" 0
        ;;
      "run" )
        koshu_param_tasklist=("${parser_commands[*]:1}")
        parser_commands_continue=false
        ;;
      * ) # Unknown commands must map to task names
        koshu_param_tasklist+=("$parser_command")
        ;;
    esac
  fi
done

if [[ "${#koshu_param_tasklist[*]}" -lt 1 ]]; then
  koshu_param_tasklist=('default')
fi

koshu_bootstrap
koshu_run koshu_param_tasklist[@]
koshu_exit "Finished executing tasks ($(koshu_array_print koshu_executed_tasks[@] ' %s '))" 0
