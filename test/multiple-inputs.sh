#!/usr/bin/env bash
set -e          # kill script if a command fails
set -o nounset  # unset values give error
set -o pipefail # prevents errors in a pipeline from being masked

source "$(dirname "$( realpath ${BASH_SOURCE[0]} )" )"/../b-log.sh  # include the script
LOG_LEVEL_ALL               # set log level to all

echo "~~ Multiple inputs ~~"
echo "In global context"
echo "fatal level"      | FATAL
echo "error level"      | ERROR
echo "warning level"    | WARN
echo "notice level"     | NOTICE
echo "info level"       | INFO
echo "debug level"      | DEBUG
echo "trace level"      | TRACE
echo ""

echo "In function context"
function defaultLogLevelsFuncContext() {
    echo "fatal level"      | FATAL
    echo "error level"      | ERROR
    echo "warning level"    | WARN
    echo "notice level"     | NOTICE
    echo "info level"       | INFO
    echo "debug level"      | DEBUG
    echo "trace level"      | TRACE
}
defaultLogLevelsFuncContext
