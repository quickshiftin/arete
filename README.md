arete
=====

Multi-host SSH command executor in BASH. Arete is inspired by tools like [Capistrano](http://capistranorb.com/) and [Fabric](http://docs.fabfile.org/en/1.8/), more so the later. These tools are incredibly useful, but having written a large chunk of BASH code for building and packaging software, I found myself wanting a BASH option for running SSH across a number of remote hosts.

`arete` is much simpler than its Ruby and Python counterparts. I wanted to keep the interface of `arete` very simple so there are some limitations. One thing is `arete` will not enter username and password at an interactive prompt; SSH keys are a requirement. You'll find in similar fashion, there aren't a ton of options with `arete`, it's a minimal tool that aims to hit the 80 of the 80/20 rule.

arete-files
-----------
Similar in nature to `fabfiles`, `arete-files` allow you to define files of *tasks*. You may also define sets of hosts in these files.

**Defining Hosts in arete-files**

You define groups of hosts in `arete` by putting them into BASH arrays. You can think of these arrays as *roles*.
```bash
# Defne the hosts
STAGING_HOSTS=( deploy-user@app1-staging.mysite.com deploy-user@app2-staging.mysite.com )
PRODUCTION_HOSTS=( deploy-user@app1.mysite.com deploy-user@app2.mysite.com )
```
Notice that you need to enter hosts with the user you wish to connect as. You'll also need to have ssh public keys for said user on the remote systems for the user on the local machine you will be running `arete` as. So if you want you **jenkins** user to connect as **deploy-user** as the host definitions above suggest, you would put the **jenkins** `id-rsa.pub` file contents in `~/.ssh/authorized_keys` on the hosts enumerated in the `STAGING_HOSTS` and `PRODUCTION_HOSTS` roles.

**Important: `arete` only works with SSH keys. It does not automatically enter credentials for interactive sessions.**

**Defining Tasks in arete-files**

You define tasks by prefixing a function name with `task_`. In arete, you need to define task functions with the following syntax
```bash
#------------------------
# Ignored comment section
#------------------------
# Comment for CLI listing
function task_<task name>
{
  # Calls to arete_run et al
}
```

**Enabling Asynchronous execution**

You must define a global variable `ARETE_ASYNC=1` to enable asynchronous mode. You can confine synchronous and asynchronous execution to certain blocks of execution by setting it prior to any invocation of `arete_run` et al.

running `arete`
---------------
You can use `arete` to run ad-hoc commands across a group of hosts or you can use it to load tasks from an `arete-file`.

**Using `arete` for ad-hoc commands**

Documentation coming soon.

**Using `arete` to run tasks**

You need to point `arete` to an `arete-file`.
```bash
arete ~/path-to/arete-file.sh
```
Given the following `arete-file`
```bash
#------------------------
# Ignored comment section
#------------------------
# Update apt
function task_apt_update
{
  # Calls to arete_hosts, arete_run et al
  arete_hosts "${HOSTS[@]}"
  arete_run "sudo apt-get update"
}
```
The command line will list out the the tasks.
```bash
$ arete ./arete-file.sh 
    update_apt             # Update apt
```

**Intelligent Execution of Sub-Tasks**

Once you start writing `arete-files`, you will find the need to have abstract functions that can be applied to arbitrary sets of hosts. You can do this simply with `arete` by definining *private* functions. You don't have to, but I like to prefix these methods with `_task_` when I name them. As long as they aren't defined like we discussed in **Defining Tasks in arete-files**, they won't show up in `arete` task listings on the command line. The other defining characteristic of *sub tasks* is they don't call `arete_hosts`, rather they expect the calling *high level* tasks to call `arete_hosts` beforehand.
```bash
# Defne the hosts
STAGING_HOSTS=( app1-staging.mysite.com app2-staging.mysite.com )
PRODUCTION_HOSTS=( app1.mysite.com app2.mysite.com )

#------------------------------------------------
# Reusable sub-task to list the hostname and date
#------------------------------------------------
function _task_host_date
{
    arete_run "echo \$(hostname) \- \$(date);"
}

#------------------------------------------------
# This command runs the _task_host_date sub-task
# on the hosts in the $STAGING_HOSTS[@] array.
#------------------------------------------------
# Dump the hostname and date in staging
function task_staging_host_date
{
    arete_hosts "${STAGING_HOSTS[@]}"
    _task_host_date
}

#------------------------------------------------
# This command runs the _task_host_date sub-task
# on the hosts in the $PRODUCTION_HOSTS[@] array.
#------------------------------------------------
# Dump the hostname and date in production
function task_production_host_date
{
    arete_hosts "${PRODUCTION_HOSTS[@]}"
    _task_host_date
}
```

**Uploading files to remote hosts**

```bash
#------------------------------------------------
# This command upload a local zip file to all the
# servers in the $HOSTS[@] array.
#------------------------------------------------
# Test the arete_put function
function task_test_put
{
    local local_file=~/Downloads/data.zip
    local basename=$(basename "$local_file")

    arete_hosts "${HOSTS[@]}"
    arete_put "$local_file" "~/${basename}"
    arete_run "ls ~/$basename"
}
```


**Downloading files from remote hosts**

Coming Soon.

**Exportig BASH functions**

Coming Soon.

arete API
-----------
**arete globals**

`ARETE_ASYNC` - Whether or not to execute the remote commands in serial or parallel

`ARETE_HOSTS` - The list of hosts to execute the current set of commands against

**arete functions**

`arete_run`   - Execute one or more commands on all hosts in `ARETE_HOSTS`

`arete_put`   - Upload a file to all the hosts in `ARETE_HOSTS`

`arete_get`   - Download a file from all the hosts in `ARETE_HOSTS`

`arete_hosts` - Append to the list of hosts, `ARETE_HOSTS`
