#!/usr/bin/env bash
#########################################################################
# Script Name: b-log
# Script Version: See B_LOG_VERSION
# Script Date: 30 June 2016
#########################################################################
#
# a bash-logging interface, hence the name b-log.
# pronounced as 'bee log' or 'blog'... whatever you like.
#########################################################################
# include guard
[ -n "${B_LOG_SH+x}" ] && return || readonly B_LOG_SH=1

# global parameters
# default disable these settings
#set -e          # kill script if a command fails
#set -o nounset  # unset values give error
#set -o pipefail # prevents errors in a pipeline from being masked

B_LOG_APPNAME="b-log"
B_LOG_VERSION=1.2.0

# --- global variables ----------------------------------------------
# log levels
readonly LOG_LEVEL_OFF=0        # none
readonly LOG_LEVEL_FATAL=100    # unusable, crash
readonly LOG_LEVEL_ERROR=200    # error conditions
readonly LOG_LEVEL_WARN=300     # warning conditions
readonly LOG_LEVEL_NOTICE=400   # Nothing serious, but notably nevertheless.
readonly LOG_LEVEL_INFO=500     # informational
readonly LOG_LEVEL_DEBUG=600    # debug-level messages
readonly LOG_LEVEL_TRACE=700    # see stack traces
readonly LOG_LEVEL_ALL=-1       # all enabled

#############################
# Log template
#############################
# template based on a number between '@x@'
# so the following @a:b@ means:
# a is the string length and b is the selector
# or @a@ means:
# a is the selector
# so, @1@ will return the timestamp
# and @5:1@ will return the timestamp of string length 5
# selector: item
# 1: timestamp
# 2: log level name
# 3: function name
# 4: line number
# 5: log message
# 6: space
# 7: filename
B_LOG_DEFAULT_TEMPLATE="[@23:1@][@6:2@][@3@:@3:4@] @5@"  # default template

# log levels information
# level code, level name, level template, prefix(colors etc.), suffix(colors etc.)
LOG_LEVELS=(
    "${LOG_LEVEL_FATAL}"  "FATAL"  "${B_LOG_DEFAULT_TEMPLATE}" "\e[41;37m" "\e[0m"
    "${LOG_LEVEL_ERROR}"  "ERROR"  "${B_LOG_DEFAULT_TEMPLATE}" "\e[1;31m" "\e[0m"
    "${LOG_LEVEL_WARN}"   "WARN"   "${B_LOG_DEFAULT_TEMPLATE}" "\e[1;33m" "\e[0m"
    "${LOG_LEVEL_NOTICE}" "NOTICE" "${B_LOG_DEFAULT_TEMPLATE}" "\e[1;32m" "\e[0m"
    "${LOG_LEVEL_INFO}"   "INFO"   "${B_LOG_DEFAULT_TEMPLATE}" "\e[37m" "\e[0m"
    "${LOG_LEVEL_DEBUG}"  "DEBUG"  "${B_LOG_DEFAULT_TEMPLATE}" "\e[1;34m" "\e[0m"
    "${LOG_LEVEL_TRACE}"  "TRACE"  "${B_LOG_DEFAULT_TEMPLATE}" "\e[94m" "\e[0m"
)
# log levels columns
readonly LOG_LEVELS_LEVEL=0
readonly LOG_LEVELS_NAME=1
readonly LOG_LEVELS_TEMPLATE=2
readonly LOG_LEVELS_PREFIX=3
readonly LOG_LEVELS_SUFFIX=4

LOG_LEVEL=${LOG_LEVEL_WARN}               # current log level
B_LOG_LOG_VIA_STDOUT=true                 # log via stdout
B_LOG_LOG_VIA_STDOUT_NO_TEMPLATE=false    # use log level template by default
B_LOG_LOG_VIA_FILE=""                     # file if logging via file (file, add suffix, add prefix)
B_LOG_LOG_VIA_FILE_PREFIX=false           # add prefix to log file
B_LOG_LOG_VIA_FILE_SUFFIX=false           # add suffix to log file
B_LOG_LOG_VIA_SYSLOG=""                   # syslog flags so that "syslog 'flags' message"
B_LOG_TS=""                               # timestamp variable
B_LOG_TS_FORMAT="%Y-%m-%d %H:%M:%S.%N"    # timestamp format
B_LOG_LOG_LEVEL_NAME=""                   # the name of the log level
B_LOG_LOG_MESSAGE=""                      # the log message

function B_LOG_ERR() {
    # @description internal error message handler
    # @param $1 return code of a command etc.
    # @param $2 message when return code is 1
    local return_code=${1:-0}
    local return_message=${2:=""}
    local prefix="\e[1;31m" # error color
    local suffix="\e[0m"    # error color
    if [ $return_code -eq 1 ]; then
        echo -e "${prefix}${return_message}${suffix}"
    fi
}

function B_LOG(){
    # @description setup interface
    # see -h for help
    local OPTIND=""
    function PRINT_USAGE() {
        # @description prints the short usage of the script
        echo ""
        echo "Usage: B_LOG [options]"
        echo "  -h, --help              Show usage"
        echo "  -V, --version           Version"
        echo "  -d, --date-format       Date format used in the log eg. '%Y-%m-%d %H:%M:%S.%N'"
        echo "  -o, --stdout            Log over stdout (true/false) default true."
        echo "  --stdout-no-template    Disable template for standard out"
        echo "  -f, --file              File to log to, none set means disabled"
        echo "  --file-prefix-enable    Enable the prefix for the log file"
        echo "  --file-prefix-disable   Disable the prefix for the log file"
        echo "  --file-suffix-enable    Enable the suffix for the log file"
        echo "  --file-suffix-disable   Disable the suffix for the log file"
        echo "  -s, --syslog            'switches you want to use'. None set means disabled"
        echo "                          results in: \"logger 'switches' log-message\""
        echo "  -l, --log-level         The log level"
        echo "                          Log levels       : value"
        echo "                          ---------------- : -----"
        echo "                          LOG_LEVEL_OFF    : ${LOG_LEVEL_OFF}"
        echo "                          LOG_LEVEL_FATAL  : ${LOG_LEVEL_FATAL}"
        echo "                          LOG_LEVEL_ERROR  : ${LOG_LEVEL_ERROR}"
        echo "                          LOG_LEVEL_WARN   : ${LOG_LEVEL_WARN}"
        echo "                          LOG_LEVEL_NOTICE : ${LOG_LEVEL_NOTICE}"
        echo "                          LOG_LEVEL_INFO   : ${LOG_LEVEL_INFO}"
        echo "                          LOG_LEVEL_DEBUG  : ${LOG_LEVEL_DEBUG}"
        echo "                          LOG_LEVEL_TRACE  : ${LOG_LEVEL_TRACE}"
        echo ""
    }
    for arg in "$@"; do # transform long options to short ones
        shift
        case "$arg" in
            "--help") set -- "$@" "-h" ;;
            "--version") set -- "$@" "-V" ;;
            "--log-level") set -- "$@" "-l" ;;
            "--date-format") set -- "$@" "-d" ;;
            "--stdout") set -- "$@" "-o" ;;
            "--stdout-no-template") set -- "$@" "-a" "stdout-no-template" ;;
            "--file") set -- "$@" "-f" ;;
            "--file-prefix-enable") set -- "$@" "-a" "file-prefix-enable" ;;
            "--file-prefix-disable") set -- "$@" "-a" "file-prefix-disable" ;;
            "--file-suffix-enable") set -- "$@" "-a" "file-suffix-enable" ;;
            "--file-suffix-disable") set -- "$@" "-a" "file-suffix-disable" ;;
            "--syslog") set -- "$@" "-s" ;;
            *) set -- "$@" "$arg"
      esac
    done
    # get options
    while getopts "hVd:o:f:s:l:a:" optname
    do
        case "$optname" in
            "h")
                PRINT_USAGE
                ;;
            "V")
                echo "${B_LOG_APPNAME} v${B_LOG_VERSION}"
                ;;
            "d")
                B_LOG_TS_FORMAT=${OPTARG}
                ;;
            "o")
                if [ "${OPTARG}" = true ]; then
                    B_LOG_LOG_VIA_STDOUT=true
                else
                    B_LOG_LOG_VIA_STDOUT=false
                fi
                ;;
            "f")
                B_LOG_LOG_VIA_FILE=${OPTARG}
                ;;
            "a")
                case ${OPTARG} in
                    'file-prefix-enable' )
                        B_LOG_LOG_VIA_FILE_PREFIX=true
                        ;;
                    'file-prefix-disable' )
                        B_LOG_LOG_VIA_FILE_PREFIX=false
                        ;;
                    'file-suffix-enable' )
                        B_LOG_LOG_VIA_FILE_SUFFIX=true
                        ;;
                    'file-suffix-disable' )
                        B_LOG_LOG_VIA_FILE_SUFFIX=false
                        ;;
                    'stdout-no-template' )
                        B_LOG_LOG_VIA_STDOUT_NO_TEMPLATE=true
                        ;;
                    *)
                        ;;
                esac
                ;;
            "s")
                B_LOG_LOG_VIA_SYSLOG=${OPTARG}
                ;;
            "l")
                LOG_LEVEL=${OPTARG}
                ;;
            *)
                B_LOG_ERR '1' "unknown error while processing B_LOG option."
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
    local template=${*:-}
    local selector=0
    local str_length=0
    local to_replace=""
    local log_layout_part=""
    local found_pattern=true
    B_LOG_CONVERTED_TEMPLATE_STRING=""
    while $found_pattern ; do
        if [[ "${template}" =~ @[0-9]+@ ]]; then
            to_replace=${BASH_REMATCH[0]}
            selector=${to_replace:1:(${#to_replace}-2)}
        elif [[ "${template}" =~ @[0-9]+:[0-9]+@ ]]; then
            to_replace=${BASH_REMATCH[0]}
            if [[ "${to_replace}" =~ @[0-9]+: ]]; then
                str_length=${BASH_REMATCH[0]:1:(${#BASH_REMATCH[0]}-2)}
            else
                str_length=0
            fi
            if [[ "${to_replace}" =~ :[0-9]+@ ]]; then
                selector=${BASH_REMATCH[0]:1:(${#BASH_REMATCH[0]}-2)}
            fi
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
                log_layout_part="${FUNCNAME[3]}"
                ;;
            4) # line number
                log_layout_part="${BASH_LINENO[2]}"
                ;;
            5) # message
                log_layout_part="${B_LOG_LOG_MESSAGE}"
                ;;
            6) # space
                log_layout_part=" "
                ;;
            7) # file name
                log_layout_part="$(basename ${BASH_SOURCE[3]})"
                ;;
            *)
                B_LOG_ERR '1' "unknown template parameter: '$selector'"
                log_layout_part=""
            ;;
        esac
        if [ ${str_length} -gt 0 ]; then # custom string length
            if [ ${str_length} -lt ${#log_layout_part} ]; then
                # smaller as string, truncate
                log_layout_part=${log_layout_part:0:str_length}
            elif [ ${str_length} -gt ${#log_layout_part} ]; then
                # bigger as string, append
                printf -v log_layout_part "%-0${str_length}s" $log_layout_part
            fi
        fi
        str_length=0 # set default
        template="${template/$to_replace/$log_layout_part}"
    done
    B_LOG_CONVERTED_TEMPLATE_STRING=${template}
    return 0
}

function B_LOG_print_message() {
    # @description
    # @param $1 log type
    # $2... the rest are messages
    local file_directory=""
    local err_ret_code=0
    B_LOG_TS=$(date +"${B_LOG_TS_FORMAT}") # get the date
    log_level=${1:-"$LOG_LEVEL_ERROR"}
    if [ ${log_level} -gt ${LOG_LEVEL} ]; then # check log level
        if [ ! ${LOG_LEVEL} -eq ${LOG_LEVEL_ALL} ]; then # check log level
            return 0;
        fi
    fi
    # log level bigger as LOG_LEVEL? and level is not -1? return

    shift
    local message=${*:-}
    if [ -z "$message" ]; then # if message is empty, get from stdin
        message="$(cat /dev/stdin)"
    fi

    if [ -z "$message" ]; then # if message is still empty then don't print anything
        return 0;
    fi
    
    B_LOG_LOG_MESSAGE="${message}"
    B_LOG_get_log_level_info "${log_level}" || true
    B_LOG_convert_template ${LOG_FORMAT} || true
    # output to stdout
    if [ "${B_LOG_LOG_VIA_STDOUT}" = true ]; then
        echo -ne "$LOG_PREFIX"

        if [ "${B_LOG_LOG_VIA_STDOUT_NO_TEMPLATE}" = true ]; then
          echo -ne "${B_LOG_LOG_MESSAGE}"
        else
          echo -ne "${B_LOG_CONVERTED_TEMPLATE_STRING}"
        fi

        echo -e "$LOG_SUFFIX"
    fi
    # output to file
    if [ ! -z "${B_LOG_LOG_VIA_FILE}" ]; then
        file_directory=$(dirname $B_LOG_LOG_VIA_FILE)
        if [ ! -z "${file_directory}" ]; then
            if [ ! -d "${B_LOG_LOG_VIA_FILE%/*}" ]; then # check directory
                # directory does not exist
                mkdir -p "${file_directory}" || err_ret_code=$?
                B_LOG_ERR "${err_ret_code}" "Error while making log directory: '${file_directory}'. Are the permissions ok?"
            fi
        fi
        if [ ! -e "${B_LOG_LOG_VIA_FILE}" ]; then # check file
            # file does not exist and making of folder went ok
            if [ $err_ret_code -ne 1 ]; then
                touch "${B_LOG_LOG_VIA_FILE}" || err_ret_code=$?
                B_LOG_ERR "${err_ret_code}" "Error while making log file: '${B_LOG_LOG_VIA_FILE}'. Are the permissions ok?"
            fi
        else
            message=""
            if [ "${B_LOG_LOG_VIA_FILE_PREFIX}" = true ]; then
                message="${message}${LOG_PREFIX}"
            fi
            message="${message}${B_LOG_CONVERTED_TEMPLATE_STRING}"
            if [ "${B_LOG_LOG_VIA_FILE_SUFFIX}" = true ]; then
                message="${message}${LOG_SUFFIX}"
            fi
            echo -e "${message}" >> ${B_LOG_LOG_VIA_FILE} || true
        fi
    fi
    # output to syslog
    if [ ! -z "${B_LOG_LOG_VIA_SYSLOG}" ]; then
        logger ${B_LOG_LOG_VIA_SYSLOG} "${B_LOG_CONVERTED_TEMPLATE_STRING}" || err_ret_code=$?
        B_LOG_ERR "${err_ret_code}" "Error while logging with syslog. Where these flags ok: '${B_LOG_LOG_VIA_SYSLOG}'"
    fi
}

# Define commands
# Setting of log level
function LOG_LEVEL_OFF()    { B_LOG --log-level ${LOG_LEVEL_OFF} "$@"; }
function LOG_LEVEL_FATAL()  { B_LOG --log-level ${LOG_LEVEL_FATAL} "$@"; }
function LOG_LEVEL_ERROR()  { B_LOG --log-level ${LOG_LEVEL_ERROR} "$@"; }
function LOG_LEVEL_WARN()   { B_LOG --log-level ${LOG_LEVEL_WARN} "$@"; }
function LOG_LEVEL_NOTICE() { B_LOG --log-level ${LOG_LEVEL_NOTICE} "$@"; }
function LOG_LEVEL_INFO()   { B_LOG --log-level ${LOG_LEVEL_INFO} "$@"; }
function LOG_LEVEL_DEBUG()  { B_LOG --log-level ${LOG_LEVEL_DEBUG} "$@"; }
function LOG_LEVEL_TRACE()  { B_LOG --log-level ${LOG_LEVEL_TRACE} "$@"; }
function LOG_LEVEL_ALL()    { B_LOG --log-level ${LOG_LEVEL_ALL} "$@"; }

# Log commands
function B_LOG_MESSAGE() { B_LOG_print_message "$@"; }

function FATAL()    { B_LOG_print_message ${LOG_LEVEL_FATAL} "$@"; }
function ERROR()    { B_LOG_print_message ${LOG_LEVEL_ERROR} "$@"; }
function WARN()     { B_LOG_print_message ${LOG_LEVEL_WARN} "$@"; }
function NOTICE()   { B_LOG_print_message ${LOG_LEVEL_NOTICE} "$@"; }
function INFO()     { B_LOG_print_message ${LOG_LEVEL_INFO} "$@"; }
function DEBUG()    { B_LOG_print_message ${LOG_LEVEL_DEBUG} "$@"; }
function TRACE()    { B_LOG_print_message ${LOG_LEVEL_TRACE} "$@"; }
