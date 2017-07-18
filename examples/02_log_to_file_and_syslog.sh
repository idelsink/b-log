#!/usr/bin/env bash
# example: 02 - log to file and syslog
source "$(dirname "$( realpath ${BASH_SOURCE[0]} )" )"/../b-log.sh  # include the script
LOG_LEVEL_ALL               # set log level to all
B_LOG --file log.txt --file-prefix-enable --file-suffix-enable
B_LOG --syslog '--tag b-log_example_02'
FATAL   "fatal level"
ERROR   "error level"
WARN    "warning level"
NOTICE  "notice level"
INFO    "info level"
DEBUG   "debug level"
TRACE   "trace level"
echo "Printing the tail of last 7 messages '/var/log/syslog'"
tail -n 7 /var/log/syslog
