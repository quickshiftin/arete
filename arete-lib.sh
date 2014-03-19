#!/bin/bash
#-----------------------------------------------------------------
# A BASH multi-host command executor, similar to Fabric in Python.
#-----------------------------------------------------------------

#------------------------------------------------------------
# scp wrapper for arete. This allows you to upload a file to
# an arbitrary set of remote machines.
#------------------------------------------------------------
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

#------------------------------------------------------------
# Run an arbitrary command on a number of remote machines.
# The command can be run synchronously or asynchronously.
#------------------------------------------------------------
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

#------------------------------------------------------------
# Append a single host to the list of hosts unless the host
# is already present in the list.
#------------------------------------------------------------
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

#------------------------------------------------------------
# Build a list of hosts to be used for remote execution. The
# arguments can be single hostnames or arrays, they will all
# be merged into a final list by arete_hosts.
#------------------------------------------------------------
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

#------------------------------------------------------------
# Execute a single task given its name (which is the function
# name exclusive of the 'task_' prefix).
#------------------------------------------------------------
function arete
{
    local task="$1"
    if [ $(type -t "task${1}")"" == 'function' ]; then
        task="task_${1}"
    fi

    # For now arguments are any extra params, but at some point
    # let's take in args like fabric does :-delimited so hosts
    # can be specified on the fly
    "$task"
}
