#!/usr/bin/env bash

# init

set -e
trap koshu_exit INT TERM EXIT

# parameters

declare -a koshu_param_tasklist=()
declare koshu_param_taskfile='./koshufile'
declare koshu_param_silent=false
declare koshu_param_verbose=false

# koshufile aliases

shopt -s expand_aliases

alias task='function'
alias depends_on='koshu_exec_task'
alias global_params='koshu_allow_global_param'
alias params='koshu_allow_param'
alias color='koshu_log'
alias log='koshu_log default [koshu] '
alias log_verbose='koshu_log_verbose [koshu] '
alias log_success='koshu_log green [koshu] '
alias log_info='koshu_log blue [koshu] '
alias log_warn='koshu_log yellow [koshu] '
alias log_error='koshu_log red [koshu] '



# internals

declare -r koshu_version='0.7.0'
declare koshu_exiting=false
declare -a koshu_available_tasks=()
declare -a koshu_executed_tasks=()
declare -a koshu_allowed_params=()
declare -a koshu_arg_params=()
declare -a koshu_arg_envs=()
declare here

function koshu_print_version () {
  koshu_log default "Koshu $koshu_version"
}

function koshu_print_logo () {
  koshu_log blue "${koshu_color_reset}${koshu_color_blue} _  __         _
| |/ /___  ___| |__  _   _
| ' // _ \/ __| '_ \| | | |
| . \ (_) \__ \ | | | |_| |
|_|\_\___/|___/_| |_|\__,_|
======================================================
Koshu - The honey flavoured task automation tool
======================================================${koshu_color_reset}
"
}

function koshu_print_usage () {
  log_info "Koshu $koshu_version"
  log_info "Usage: ./koshu.sh [<command|task>] [--<option>]"
}

function koshu_print_help () {
  koshu_print_logo
  koshu_print_usage
  log_verbose
  log_verbose "  The first argument must be a <command> or a <task> where"
  log_verbose "  the value is the name of a task you wish to execute"
  log_verbose "  or the name of a koshu command."
  log_verbose
  log_verbose "  commands:"
  log_verbose "    init                        Initialized koshu"
  log_verbose "    help                        Displays this help message"
  log_verbose "    version                     Displays the version number"
  log_verbose "    tasks                       Lists available tasks"
  log_verbose "    run <task1> <task2>         Run task"
  log_verbose
  log_verbose "  options:"
  log_verbose "    -s, --silent                Suppress output from koshu"
  log_verbose "    -v, --verbose               Show verbose output from koshu"
  log_verbose "    -f <file>, --file <file>    Specifies the path to the koshufile (default ./koshufile)"
  log_verbose "    -p <name=value>, --param <name=value>    Sets variable before tasks are executed"
  log_verbose "    -e <name=value>, --env <name=value>    Sets environment variable before tasks are executed"
  log_verbose
  log_verbose "  examples:"
  log_verbose "    ./koshu.sh compile"
  log_verbose "    ./koshu.sh test:all --file ./path/to/koshufile"
  log_verbose
}

# shellcheck disable=SC2034
declare -r koshu_color_default=''
# shellcheck disable=SC2034
declare -r koshu_color_blue="\033[1;94m"
# shellcheck disable=SC2034
declare -r koshu_color_green="\033[1;92m"
# shellcheck disable=SC2034
declare -r koshu_color_red="\033[0;91m"
# shellcheck disable=SC2034
declare -r koshu_color_yellow="\033[0;93m"
# shellcheck disable=SC2034
declare -r koshu_color_gray="\033[0;90m"
# shellcheck disable=SC2034
declare -r koshu_color_reset="\033[0m"

function koshu_log () {
  [[ $koshu_param_silent = true ]] || {
    koshu_log_color=koshu_color_${1}; echo -e "${koshu_color_reset}${!koshu_log_color}${*:2}${koshu_color_reset}";
  }
}

function koshu_log_verbose () {
  [[ $koshu_param_verbose = false ]] || {
    koshu_log gray "$@"
  }
}

function koshu_exit () {
  local exitcode=${2:-$?}

  if [[ $koshu_exiting = false ]]; then
    local msg=${1:-""}

    if [[ $exitcode = 0 ]]; then
      if [[ "$msg" != "" ]]; then
        log_success "$msg"
      fi
    else
      log_error "${msg:-An unhandled error occured.}"
      log_error "Exit code: $exitcode"
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

function koshu_exec_task () {
  local task_name=${1}
  local executed
  local start_time
  local end_time

  executed=$(koshu_array_contains "$task_name" "${koshu_executed_tasks[@]}")
  if [[ $executed = false ]]; then
    # ensure here is set properly before executing task
    koshu_set_here

    log_info "Starting $task_name"
    start_time="$(date +%s)"

    $task_name

    end_time="$(date +%s)"
    log_info "Finished $task_name ( $((end_time - start_time))s )"

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

function koshu_allow_global_param () {
  local arr=(${@})
  for p in "${arr[@]}"; do
    koshu_allowed_params+=("koshu_global_param:$p")
  done
}

function koshu_allow_param () {
  local task_name="$1"
  local arr=(${@:2})
  for p in "${arr[@]}"; do
    koshu_allowed_params+=("$task_name:$p")
  done
}

function koshu_set_param () {
  local value="$1"
  local param_name="${value%=*}"
  local param_value="${value#*=}"

  if [ "$param_name" != "" ] && [ "$param_name" != "$param_value[0]" ]; then
    printf -v "${param_name}" '%s' "${param_value}"
    koshu_params+=("$param_name")
  fi
}

function koshu_set_env () {
  local value="$1"
  local env_name="${value%=*}"
  local env_value="${value#*=}"

  if [ "$env_name" != "" ] && [ "$env_name" != "$env_value[0]" ]; then
    eval "export $env_name'=${env_value}'"
  fi
}

function koshu_init () {
  log_verbose 'Initializing koshu'
  if [[ ! -f "$koshu_param_taskfile" ]]; then
    log_verbose "Creating koshufile ($koshu_param_taskfile)"

    echo "#!/usr/bin/env bash

task default {
  echo 'Hello world!'
}
" > "$koshu_param_taskfile"
  log_info 'Created koshufile'
  else
    log_warn "Koshufile already exists ($koshu_param_taskfile)"
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
  chmod +xrw "$koshu_param_taskfile"

  # shellcheck source=/dev/null
  source "$koshu_param_taskfile" --source-only

  # set environment variables
  for e in "${koshu_arg_envs[@]}"; do
    koshu_set_env "$e"
  done

  # variable must be set after importing koshufile
  koshu_functions=($(declare -F | sed 's/declare -f //g'))

  for f in "${koshu_functions[@]}"; do
    if [[ $f != koshu_* ]] && [[ $f != _* ]]; then
      koshu_available_tasks+=("$f")
    fi
  done
}

function koshu_run () {
  local tasklist=("${!1}")

  for t in "${tasklist[@]}"; do
    if [[ "$(koshu_array_contains "$t" "${koshu_available_tasks[@]}")" = "true" ]]; then
      # set variables before task execution
      local param_old_values=()
      for p in "${koshu_arg_params[@]}"; do
        local param_name="${p%=*}"
        param_old_values+=("$param_name=${!param_name}")
        if [[ "$(koshu_array_contains "koshu_global_param:$param_name" "${koshu_allowed_params[@]}")" = "true" ]] ||[[ "$(koshu_array_contains "$t:$param_name" "${koshu_allowed_params[@]}")" = "true" ]] || [[ ${#koshu_allowed_params[@]} -eq 0 ]]; then
          koshu_set_param "$p"
        fi
      done

      koshu_exec_task $t

      # reset variables after task execution
      for p in "${param_old_values[@]}"; do
        koshu_set_param "$p"
      done
    else
      koshu_print_usage
      log_info "Run \"koshu help\" for more info."
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
  if [[ "$parser_option" =~ ^([^=]+)=(.*)$ ]]; then
    parser_key="${BASH_REMATCH[1]}"
    parser_value="${BASH_REMATCH[2]}"
  else
    parser_key=$(${parser_option//=/ }[0])
    parser_value=${parser_option#*=}
  fi

  case "$parser_key" in
    "f" | "file" )
      koshu_param_taskfile="$parser_value"
      ;;
    "p" | "param" )
      koshu_arg_params+=("$parser_value")
      ;;
    "e" | "env" )
      koshu_arg_envs+=("$parser_value")
      ;;
    "s" | "silent" )
      koshu_param_silent=true
      ;;
    "v" | "verbose" )
      koshu_param_verbose=true
      ;;
    * )
      koshu_print_usage >&2
      koshu_exit "Invalid option '$parser_key'" 1
      ;;
  esac
done

declare parser_commands_continue=true
for parser_command in "${parser_commands[@]}"; do
  if [[ $parser_commands_continue == true ]]; then
    case "$parser_command" in
      "help" )
        koshu_print_help
        koshu_exit '' 0
        ;;
      "version" )
        koshu_print_version
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
        koshu_param_tasklist=("${parser_commands[@]:1}")
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
koshu_exit "Finished executing ($(koshu_array_print koshu_executed_tasks[@] ' %s '))" 0
