#!/bin/bash
#########################################################################
# Script Name: b-log
# Script Version: 0.0.1
# Script Date: 30 June 2016
#########################################################################
#
# a bash-logging interface, hence the name b-log.
# pronounced as 'bee log' or 'blog'... whatever you like.
#########################################################################
# global parameters
set -e          # kill script if a command fails
set -o nounset  # unset values give error
set -o pipefail # prevents errors in a pipeline from being masked

VERSION_B_LOG=0.0.1
APPNAME_B_LOG="b-log"

# --- global variables ----------------------------------------------
# log levels
readonly LOG_LEVEL_OFF=0        # none
readonly LOG_LEVEL_FATAL=100    # unusable, crash
readonly LOG_LEVEL_ERROR=200    # error conditions
readonly LOG_LEVEL_WARN=300     # warning conditions
readonly LOG_LEVEL_INFO=400     # informational
readonly LOG_LEVEL_DEBUG=500    # debug-level messages
readonly LOG_LEVEL_TRACE=600    # see stack traces
readonly LOG_LEVEL_ALL=700      # all enabled

#############################
# Log template
#############################
# template based on a number between '@x@'
# so, @1@ will return the timestamp
# 1: timestamp
# 2: log level name
# 3: function name
# 4: line number
# 5: log message
# 6: space
B_LOG_DEFAULT_TEMPLATE=( "[@1@][@2@][@3@:@4@] @5@" ) # default template
# level code, level name, level template, prefix(colors etc.), suffix(colors etc.)
LOG_LEVELS=(
    ${LOG_LEVEL_FATAL}  "FATAL " "${B_LOG_DEFAULT_TEMPLATE}" "\e[41;37m" "\e[0m"
    ${LOG_LEVEL_ERROR}  "ERROR " "${B_LOG_DEFAULT_TEMPLATE}" "\e[1;31m" "\e[0m"
    ${LOG_LEVEL_WARN}   "WARN  " "${B_LOG_DEFAULT_TEMPLATE}" "\e[1;33m" "\e[0m"
    ${LOG_LEVEL_INFO}   "INFO  " "${B_LOG_DEFAULT_TEMPLATE}" "\e[37m" "\e[0m"
    ${LOG_LEVEL_DEBUG}  "DEBUG " "${B_LOG_DEFAULT_TEMPLATE}" "\e[1;34m" "\e[0m"
    ${LOG_LEVEL_TRACE}  "TRACE " "${B_LOG_DEFAULT_TEMPLATE}" "\e[94m" "\e[0m"
)
# log levels columns
readonly LOG_LEVELS_LEVEL=0
readonly LOG_LEVELS_NAME=$((LOG_LEVELS_LEVEL+1))
readonly LOG_LEVELS_TEMPLATE=$((LOG_LEVELS_NAME+1))
readonly LOG_LEVELS_PREFIX=$((LOG_LEVELS_TEMPLATE+1))
readonly LOG_LEVELS_SUFFIX=$((LOG_LEVELS_PREFIX+1))

LOG_LEVEL=${LOG_LEVEL_WARN} # current log level
B_LOG_TS=""                 # timestamp variable
B_LOG_LOG_LEVEL_NAME=""     # the level name message
B_LOG_LOG_MESSAGE=""        # the log message

function B_LOG(){
    # @description setup interface
    # see -h for help
    local OPTIND=""
    function PRINT_USAGE() {
        # @description prints the short usage of the script
        echo ""
        echo "Usage: command -hVo"
        echo "-h --help help"
        echo "-V --version version"
        echo "-l --log-level the level of the log"
        echo "  Log levels      : value"
        echo " ---------------- : -----"
        echo "  LOG_LEVEL_OFF   : ${LOG_LEVEL_OFF}"
        echo "  LOG_LEVEL_FATAL : ${LOG_LEVEL_FATAL}"
        echo "  LOG_LEVEL_ERROR : ${LOG_LEVEL_ERROR}"
        echo "  LOG_LEVEL_WARN  : ${LOG_LEVEL_WARN}"
        echo "  LOG_LEVEL_INFO  : ${LOG_LEVEL_INFO}"
        echo "  LOG_LEVEL_DEBUG : ${LOG_LEVEL_DEBUG}"
        echo "  LOG_LEVEL_TRACE : ${LOG_LEVEL_TRACE}"
        echo "-o --output destination/output directory"
        echo ""
    }
    for arg in "$@"; do # transform long options to short ones
        shift
        case "$arg" in
            "--help") set -- "$@" "-h" ;;
            "--version") set -- "$@" "-V" ;;
            "--log-level") set -- "$@" "-l" ;;
            "--output") set -- "$@" "-o" ;;
            *) set -- "$@" "$arg"
      esac
    done
    # get options
    while getopts "hVl:" optname
    do
        case "$optname" in
            "h")
                PRINT_USAGE
                ;;
            "V")
                echo "${APPNAME_B_LOG} v${VERSION_B_LOG}"
                ;;
            "l")
                LOG_LEVEL=${OPTARG}
                ;;
            *)
                echo "unknown error while processing options"
                exit 1;
            ;;
        esac
    done
    shift "$((OPTIND-1))" # shift out all the already processed options
}

function B_LOG_get_log_level_info() {
    # @description get the log level information
    # @param $1 log type
    # @return returns information in the variables
    # - log level name
    # - log level template
    # ...
    local log_level=${1:-"$LOG_LEVEL_ERROR"}
    LOG_FORMAT=""
    LOG_PREFIX=""
    LOG_SUFFIX=""
    local i=0
    for ((i=0; i<${#LOG_LEVELS[@]}; i+=$((LOG_LEVELS_SUFFIX+1)))); do
        if [[ "$log_level" == "${LOG_LEVELS[i]}" ]]; then
            B_LOG_LOG_LEVEL_NAME="${LOG_LEVELS[i+${LOG_LEVELS_NAME}]}"
            LOG_FORMAT="${LOG_LEVELS[i+${LOG_LEVELS_TEMPLATE}]}"
            LOG_PREFIX="${LOG_LEVELS[i+${LOG_LEVELS_PREFIX}]}"
            LOG_SUFFIX="${LOG_LEVELS[i+${LOG_LEVELS_SUFFIX}]}"
            return 0
        fi
    done
    return 1
}

function B_LOG_convert_template() {
    # @description converts the template to a usable string
    # only call this after filling the global parameters
    # @return fills a variable called 'B_LOG_CONVERTED_TEMPLATE_STRING'.
    local template=${@:-}
    local selector=0
    local to_replace=""
    local log_layout_part=""
    local found_pattern=true
    B_LOG_CONVERTED_TEMPLATE_STRING=""
    while $found_pattern ; do
        if [[ "${template}" =~  @[0-9]+@ ]]; then
            to_replace=${BASH_REMATCH[0]}
            selector=${to_replace:1:(${#to_replace}-2)}
        else
            found_pattern=false
        fi
        case "$selector" in
            1) # timestamp
                log_layout_part="${B_LOG_TS}"
                ;;
            2) # log level name
                log_layout_part="${B_LOG_LOG_LEVEL_NAME}"
                ;;
            3) # function name
                log_layout_part="${FUNCNAME[2]}"
                ;;
            4) # line number
                log_layout_part="${BASH_LINENO[0]}"
                ;;
            5) # message
                log_layout_part="${B_LOG_LOG_MESSAGE}"
                ;;
            6) # space
                log_layout_part=" "
                ;;
            *)
                echo "unknown template"
                log_layout_part=""
            ;;
        esac
        template="${template/$to_replace/$log_layout_part}"
    done
    B_LOG_CONVERTED_TEMPLATE_STRING=${template}
    return 0
}

function B_LOG_MESSAGE() {
    # @description
    # @param $1 log type
    # $2... the rest are messages
    B_LOG_TS=$(date +'%Y-%m-%d %H:%M:%S.%N')
    B_LOG_TS=${B_LOG_TS%??????}
    log_level=${1:-"$LOG_LEVEL_ERROR"}
    # check log level
    if [ ${log_level} -gt ${LOG_LEVEL} ]; then
        return 0;
    fi
    shift
    local message=${@:-}
    if [ -z "$message" ]; then
        message="$(cat /dev/stdin)"
    fi
    B_LOG_LOG_MESSAGE="${message}"
    B_LOG_get_log_level_info "${log_level}" || true
    B_LOG_convert_template ${LOG_FORMAT} || true
    echo -ne "$LOG_PREFIX"
    echo -ne "${B_LOG_CONVERTED_TEMPLATE_STRING}"
    echo -e "$LOG_SUFFIX"
}

# set alias for log level command
shopt -s expand_aliases
alias LOG_LEVEL_OFF="B_LOG --log-level ${LOG_LEVEL_OFF}"
alias LOG_LEVEL_FATAL="B_LOG --log-level ${LOG_LEVEL_FATAL}"
alias LOG_LEVEL_ERROR="B_LOG --log-level ${LOG_LEVEL_ERROR}"
alias LOG_LEVEL_WARN="B_LOG --log-level ${LOG_LEVEL_WARN}"
alias LOG_LEVEL_INFO="B_LOG --log-level ${LOG_LEVEL_INFO}"
alias LOG_LEVEL_DEBUG="B_LOG --log-level ${LOG_LEVEL_DEBUG}"
alias LOG_LEVEL_TRACE="B_LOG --log-level ${LOG_LEVEL_TRACE}"
alias LOG_LEVEL_ALL="B_LOG --log-level ${LOG_LEVEL_ALL}"

# set alias for log command
alias FATAL="B_LOG_MESSAGE ${LOG_LEVEL_FATAL} "
alias ERROR="B_LOG_MESSAGE ${LOG_LEVEL_ERROR} "
alias WARN="B_LOG_MESSAGE ${LOG_LEVEL_WARN} "
alias INFO="B_LOG_MESSAGE ${LOG_LEVEL_INFO} "
alias DEBUG="B_LOG_MESSAGE ${LOG_LEVEL_DEBUG} "
alias TRACE="B_LOG_MESSAGE ${LOG_LEVEL_TRACE} "
