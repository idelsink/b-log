#!/usr/bin/env bash
set -e          # kill script if a command fails
set -o nounset  # unset values give error
set -o pipefail # prevents errors in a pipeline from being masked

source "$(dirname "$( realpath ${BASH_SOURCE[0]} )" )"/../b-log.sh  # include the script
LOG_LEVEL_ALL               # set log level to all

# Register templates
for templateNr in {1..7}; do
    LOG_LEVELS+=("$((1000+${templateNr}))" "T${templateNr}" "@5@ @${templateNr}@" "" "")
done

echo "~~ Templates ~~"
echo "In global context"
B_LOG_MESSAGE 1001 "Selector 1: timestamp          -> "
B_LOG_MESSAGE 1002 "Selector 2: log level name     -> "
B_LOG_MESSAGE 1003 "Selector 3: function name      -> "
B_LOG_MESSAGE 1004 "Selector 4: line number        -> "
B_LOG_MESSAGE 1005 "Selector 5: log message        -> "
B_LOG_MESSAGE 1006 "Selector 6: space character    -> "
B_LOG_MESSAGE 1007 "Selector 7: filename           -> "
echo ""

echo "In function context"
function templatesFuncContext() {
    B_LOG_MESSAGE 1001 "Selector 1: timestamp          -> "
    B_LOG_MESSAGE 1002 "Selector 2: log level name     -> "
    B_LOG_MESSAGE 1003 "Selector 3: function name      -> "
    B_LOG_MESSAGE 1004 "Selector 4: line number        -> "
    B_LOG_MESSAGE 1005 "Selector 5: log message        -> "
    B_LOG_MESSAGE 1006 "Selector 6: space character    -> "
    B_LOG_MESSAGE 1007 "Selector 7: filename           -> "
}
templatesFuncContext
