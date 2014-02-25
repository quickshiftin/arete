#!/bin/bash

# Load the arete library
# @note May package this in a single file ...
source ./arete-lib.sh

_usage(){
  egrep "function task_|^[^_].\+(){$" $1 | while read line; do
    local cmd=$(echo "$line" | sed "s/(){//g" | sed 's/function task_//g')
    local info=$(grep -C0 -A0 -B1 "function task_$cmd" $1 | sed "N;s/\n.*//g")
    printf "    %-20s %-40s\n" "$cmd" "$info" | grep "#"
  done; echo "";
}

# Bail if functions file is not a regular file
if [ ! -f "$1" ]; then
    echo "$1" is not a regular file.
    _usage
    exit
fi

# Load the functions file and run the task
if [ $# -gt 1 ]; then
    source "$1"
    arete "$2"

# Show usage information
else
    _usage "$1"
fi
