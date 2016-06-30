#!/bin/bash
#########################################################################
# Script Name: example
# Script Version: 0.0.1
# Script Date: 30 June 2016
#########################################################################
# example of b-log.sh
#########################################################################
# global parameters
set -e          # kill script if a command fails
set -o nounset  # unset values give error
set -o pipefail # prevents errors in a pipeline from being masked

script_path=${0%/*}                 # the path to the script
source ${script_path}/../b-log.sh   # include the log script

echo "--------------------------------------------------"
echo "example of ${APPNAME_B_LOG} v${VERSION_B_LOG}"
echo "--------------------------------------------------"
echo ""
echo "** Setting the log level"
echo "B_LOG --log-level 'nr'"
echo "B_LOG --log-level '\$LOG_LEVEL_OFF'"
echo "or using the direct aliases: 'LOG_LEVEL_OFF', 'LOG_LEVEL_FATAL' ..."
echo "these are aliases that call the 'B_LOG --log-level' function"
echo ""
echo "--------------------------------------------------"
LOG_LEVEL_ALL
FATAL "fatal level"
ERROR "error level"
WARN "warning level"
INFO "info level"
DEBUG "debug level"
TRACE "trace level"
echo "--------------------------------------------------"
echo "piped into INFO" | INFO
