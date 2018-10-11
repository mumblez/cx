# cx

Context Switcher, switch configs, settings, profiles instantly for any program
cx is a tool that acts as a shim to allow context switching; to provide different
configurations to a common program, e.g. mysql, postgres, rundeck etc or to simply expose
sensitive information like an api key only for the duration the program is executed!

The goal is to make exposing sensitive information short lived and confined to just the execution
of the desired program; because we export variables and run the program in a subshell, upon
exit those variables will no longer be available in your environment.

This is further secured / enhanced if you derive your values from a cli password manager
such as pass or gopass, then you can safely version control your shims!

e.g. in a configuration file for your shim, you can do like so with gopass:

```sh
export HOMEBREW_GITHUB_API_TOKEN="$(gopass homebrew-git-pat)"
``````


## How to create a program shim:

1. Within cx base directory, make a directory after your named program, e.g.

`mkdir mysql` and cd into it
the directory name will be used as your program name and will be accessible within your `PATH`
we will shadow the program if it already exists in your path, to shadow you must ensure
`CX_BIN_DIR` is in your path earlier than your other paths (set it at the beginning!)

2. create a script named 'run', make executable and put your logic in there, logic shoud include
    - Pulling sensitive info out of [go]pass (if you don't want to put it in your configs clear text)
    - Setting config variables, e.g. host, username, password, project, instance....
    - Export the variables before calling the real program, e.g. 'mysql'
    - prefix your final command with `cx_bin_wrap`, e.g. `cx_bin_wrap mysql --defaults-file=<(echo $CONFIG)`
        - our `cx_bin_wrap` will amend `PATH` just before execution so that the real command is 
            executed (later in your `PATH`)
        - detect how the command is invoked and handle appropriately, e.g.:
            - `echo "use somedb; select * from sometable;" | mysql` # Piped content
            - `mysql -v`                                            # just regular invocation


3. create your various configurations, e.g. for different environments, instances, projects, dbs, etc..
    name then anything you want, except 'config' (that will be the symlink to the desired configuration)

4. run `cx setup`, this will create symlinks for each shim in a directory in your PATH, e.g. 
`$CX_BIN_DIR` (ensure this directory is in your PATH, ideally at the beginning!)


## How to change your program's configuration

```sh
cx <program> <config> 
```

e.g. if your shim program is named `mysql` and you have a
configuration named `staging` you'd changed to that config like so:

```sh
cx mysql staging
```

You're file layout may look like so:

```text
    -myShims/
     |-mysql/
        |-staging
        |-production
        |-run               # script to invoke
        |-config->staging   # config sourced in
```

the config symlink gets created when you `cx mysql staging`, this is what you `source` in
your `run` script, but use the `cx_get_config` function so it can return the real path!

## TODO: document
- environment variables
    - CX_BIN_DIR
    - CX_SHIMS_DIR
    - CX_COMMON_DIR
    - CX_COMMON_LIB
    - CX_BIN_LINK
    - CX_CONFIG_LINK
- bash auto complete


## How to clear your programs config

```sh
cx <program> clear
```

    e.g.

```
cx mysql clear
```

## Example: creating a shim for postgres psql tool

in your cx base directory:

```sh
mkdir psql
```
    
cd into your shim directory and create a config named anything other than `config`

```text
    $ vim staging
    PGPASSWORD=myPass       # or $(gopass postgres/staging/db-1)
    PGUSER=myUser           # or $(gopass postgres/staging/db-1 user) 
    PGHOST=1.2.3.4:5432     # or $(gopass postgres/staging/db-1 host)
```

create your `run` script (and make executable), or symlink to a real script

vim run
```sh
#!/usr/bin/bash

set -euo pipefail

# Bring in common functions and config
. "${CX_COMMON_LIB}"
. "${CX_COMMON_DIR}/trap-handler"
. "${CX_COMMON_DIR}/csp"
. "$(cx_get_config)"

# Validate we have the tools
cx_validate_tools gopass cloud_sql_proxy psql grep

# Settings
GP_CMD=(gopass show -o "$GP_ENTRY")
CSP_INSTANCE=$("${GP_CMD[@]}" csp)
PGPASSWORD=$("${GP_CMD[@]}")
PGUSER=$("${GP_CMD[@]}" user)
SOCKET_DIR=$(mktemp -d /tmp/csps-XXX)
PGHOST="${SOCKET_DIR}/${CSP_INSTANCE}"

# Start cloud_sql_proxy and wait for it to be ready
csp_start "$CSP_INSTANCE" "$SOCKET_DIR"

# Export connection info and launch psql
export PGUSER PGHOST PGPASSWORD
cx_bin_wrap psql -w "$@"

```
