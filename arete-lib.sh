#!/bin/bash
#-----------------------------------------------------------------
# A BASH multi-host command executor, similar to Fabric in Python.
#-----------------------------------------------------------------

# scp wrapper for arete
function arete_put
{
    local local_file="$1"
    local remote_path="$2"

    # Loop over the commands running them on the target boxes
    for host in "${ARETE_HOSTS[@]}"; do
        if [ $ARETE_ASYNC -eq 1 ]; then
            ( scp "$local_file" "$host":"$remote_path") &
        else
            scp "$local_file" "$host":"$remote_path"
        fi
    done

    # Wait for the background jobs in async mode
    if [ $ARETE_ASYNC -eq 1 ]; then
        wait
    fi
}

# Async mode, spit out the hostname from each box
# Async mode, spit out the hostname from each box
function arete_run
{
    local command="$1"

    # Loop over the commands running them on the target boxes
    for host in "${ARETE_HOSTS[@]}"; do
        if [ $ARETE_ASYNC -eq 1 ]; then
            ( ssh -tt "$host"  "bash -c '$command'") &
        else
            ssh -tt "$host" "bash -c '$command'"
        fi
    done

    # Wait for the background jobs in async mode
    if [ $ARETE_ASYNC -eq 1 ]; then
        wait
    fi
}

function arete_append_host
{
    # Create with initial element
    if [ -z "$ARETE_HOSTS" -o "${#ARETE_HOSTS[@]}" -eq 0 ]; then
        ARETE_HOSTS=("$1")

    # Append to the array
    else
        # Check the array to see if the host is already present
        case "${ARETE_HOSTS[@]}" in  *"$1"*) return 0 ;; esac

        ARETE_HOSTS+=("$1")
    fi
}

function arete_hosts
{
    local a=
    local is_array=
    local arg=
    local inner_arg=

    # Loop over args
    for arg in $(seq $#); do
        # If argument is not an array, simply append it
        a="${!arg}"
        is_array=$(declare -p a 2> /dev/null | grep -q '^declare \-a' | wc -l)
        if [ "$is_array" -eq 1 ]; then
            for inner_arg in ${a[@]}; do
                arete_append_host $a["$inner_arg"]
            done
        else
            arete_append_host "$a"
        fi
    done
}

function arete
{
    local task="task_${1}"

    # For now arguments are any extra params, but at some point
    # let's take in args like fabric does :-delimited so hosts
    # can be specified on the fly
    "$task"
}
