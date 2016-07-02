#!/bin/bash
# example: 01 - basic example
source ${0%/*}/../b-log.sh  # include the script
LOG_LEVEL_ALL               # set log level to all
FATAL   "fatal level"
ERROR   "error level"
WARN    "warning level"
INFO    "info level"
DEBUG   "debug level"
TRACE   "trace level"
