#!/bin/bash

# Load the arete library
# @note May package this in a single file ...
if [ -f ./arete-lib.sh ]; then
    source ./arete-lib.sh
elif [ -f /usr/share/arete-lib.sh ]; then
    source /usr/share/arete-lib.sh
else
    echo 'Failed to load library file.'
    exit 1
fi

function _usage
{
    # If the invocation to arete was total garbage...
    if [ -z "$1" ]; then
        echo "$0" '[-s]' '<task>[:arg1,..argx]' '[host1 hostX]'
        return
    fi

    # If there's an 'arete file' to analyze, then do it
    egrep "function task_|^[^_].\+(){$" $1 | while read line; do
        # Tasks must be declared as function task_<task name>
        local cmd=$(echo "$line" | sed "s/(){//g" | sed 's/function task_//g')

        # Look for comments on top of the task, the last line of comments will
        # be used for the listing output
        local info=$(grep -C0 -A0 -B1 "function task_$cmd" $1 | sed "N;s/\n.*//g")

        # Print the name of the task and optionally a comment
        if [ -z "$info" ]; then
            printf "    %-20s\n" "$cmd"
        else
            printf "    %-20s %-40s\n" "$cmd" "$info" | grep "#"
        fi
    done; echo "";
}

# Process the arguments
ARETE_ASYNC=0
while getopts "ah" OPTION; do
    case "$OPTION" in
        a)
            ARETE_ASYNC=1
            ;;
        h)
            _usage
            exit 0
        #?)
        #    _usage
        #    exit 1
        #    ;;
    esac
done

# Bail if functions file is not a regular file
if [ ! -z "$1" -a ! -f "$1" ]; then
    echo Arete file "$1" is not a regular file.
    _usage
    exit 1
fi

# Load the functions file and run the task
if [ $# -gt 1 ]; then
    source "$1"
    arete "$2"

# Show usage information
else
    _usage "$1"
    exit 1
fi
