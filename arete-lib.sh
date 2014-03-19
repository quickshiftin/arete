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
#
# Rather than run arete_ensure_host_known ad nauseam in
# arete_run, let's run it when the hosts are added in the
# first place.
#------------------------------------------------------------
function arete_append_host
{
    # Create with initial element
    if [ -z "$ARETE_HOSTS" -o "${#ARETE_HOSTS[@]}" -eq 0 ]; then
        ARETE_HOSTS=("$1")
        arete_ensure_host_known "$1"

    # Append to the array
    else
        # Check the array to see if the host is already present
        case "${ARETE_HOSTS[@]}" in  *"$1"*) return 0 ;; esac

        ARETE_HOSTS+=("$1")
        arete_ensure_host_known "$1"
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

        # Iterate over array items, appending them individually
        a="${!arg}"
        is_array=$(declare -p a 2> /dev/null | grep -q '^declare \-a')
        if [ "$is_array" -eq 0 ]; then
            for inner_arg in "${a[@]}"; do
                arete_append_host $a["$inner_arg"]
            done

        # If argument is not an array, simply append it
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

#------------------------------------------------------------
# Try every way we know how to connect to the remote host and
# cause an entry to be made in ~/.ssh/known_hosts. Host here
# is expected to be in the form <user>@<host>
#------------------------------------------------------------
function arete_ensure_host_known
{
    local arete_host=$1
    if [ -z "$arete_hsot" ]; then
        cli-msg error 'No arete host specified'
        exit 1
    fi

    # Loop over the various ways to connect to a remote host via ssh
    for _type in ssh github gitolite; do

        _arete_ensure_host_known "$arete_host" "$_type" >/dev/null 2>&1

        # If the command succeeded so have we
        if [ $? -eq 0 ]; then
            return 0
        fi
    done

    return 1
}

#-----------------------------------
# Given a string like <user>@<host>,
# split the components into an array
#-----------------------------------
function _arete_split_host
{
    local host_info=(${1//@/ })

    # @note $user & $_host are expected to be locally
    #       defined by the calling function
    _user=${host_info[0]}
    _host=${host_info[1]}
}

#--------------------------------------------------------------------------------------
# Ensure there is an entry in known hosts file for given host
# and user. What this does is prevent further commands from
# prompting when logging into a host for the first time.
#
# @note $target defaults to true, b/c the function was originally written for github
#
# @param $1 ssh_user - The remote user to login as
# @param $2 ssh_host - The remote host to login to
# @param $3 target - Is the remote host a github box; optional, default is 0
#--------------------------------------------------------------------------------------
function _arete_ensure_host_known
{
    local raw_host="$1"
    local _user=
    local _host=

    # Extract the hostname from the raw host so we can search the know_hosts file
    _arete_split_host

    # Look for the host in the hosts files first
    # @note Hit to disk
    occurances=$(grep "$_host" ~/.ssh/known_hosts | wc -l)

    # Only run ssh if there is no entry
    # @note Hit to network
    if [ $occurances -eq 0 ]; then
        case "$target" in
            gitolite)
            success=$(ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no \
                      "$raw_host" help >/dev/null 2>&1 && echo up || echo down)
            if [ $success == 'down' ]; then
                exit 3
            fi
            ;;

            github)
            # There's a semi-abnormal approach to handle github, since they don't let you
            # actually log in
            success=$(ssh -o StrictHostKeyChecking=no -T "$raw_host")
            if [[ "$success" != *'successfully authenticated'* ]]; then
                exit 4
            fi
            ;;

            ssh)
            # On regular boxes though, we'll log in and run the cd builtin
            success=$(ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no \
                      "$raw_host" cd && echo up || echo down)
            if [ $success == 'down' ]; then
                exit 5
            fi
            ;;

            *)
            exit 255
            ;;
        esac
    fi

    # Let's check up on ourselves, if the above command worked
    # there should be an entry in the known_hosts now
    occurances=$(grep "$ssh_host" ~/.ssh/known_hosts | wc -l)
    if [ "$occurances" -gt 0 ]; then
        return 0
    else
        return 6
    fi
}
