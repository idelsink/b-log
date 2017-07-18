#!/usr/bin/env bash
# example: 03 - custom log level and template
source "$(dirname "$( realpath ${BASH_SOURCE[0]} )" )"/../b-log.sh  # include the script
LOG_LEVEL_ALL               # set log level to all
FATAL   "fatal level"
ERROR   "error level"
WARN    "warning level"
NOTICE  "notice level"
INFO    "info level"
DEBUG   "debug level"
TRACE   "trace level"
# add new log level with the following:
# level nr: 50
# level name: EXAMPLE
# template: timestamp(only time) name [message]
B_LOG --date-format "%H:%M:%S.%N" # set timestamp format
LOG_LEVELS+=("50" "EXAMPLE" "@12:1@ @2@ [@5@]" "\e[37m" "\e[0m") # add custom log level
B_LOG_MESSAGE 50 "example log message"
WARN "all the normal levels still work, with the new date-format of course"
