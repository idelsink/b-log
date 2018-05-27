#!/usr/bin/env bash
set -e          # kill script if a command fails
set -o nounset  # unset values give error
set -o pipefail # prevents errors in a pipeline from being masked

source "$(dirname "$( realpath ${BASH_SOURCE[0]} )" )"/../b-log.sh  # include the script
LOG_LEVEL_ALL               # set log level to all
B_LOG --file multiple-outputs.txt --file-prefix-enable --file-suffix-enable

echo "~~ Multiple outputs ~~"
echo "In global context"
FATAL   "fatal level"
ERROR   "error level"
WARN    "warning level"
NOTICE  "notice level"
INFO    "info level"
DEBUG   "debug level"
TRACE   "trace level"
echo ""

echo "In function context"
function defaultLogLevelsFuncContext() {
    FATAL   "fatal level"
    ERROR   "error level"
    WARN    "warning level"
    NOTICE  "notice level"
    INFO    "info level"
    DEBUG   "debug level"
    TRACE   "trace level"
}
defaultLogLevelsFuncContext
echo ""

echo "File contents:"
cat multiple-outputs.txt
rm -f multiple-outputs.txt
