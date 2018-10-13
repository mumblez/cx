# cx

Context Switcher, switch configs, settings, profiles instantly for any program
cx is a tool that acts as a shim to allow context switching; to provide different
configurations to a common program, e.g. mysql, postgres, rundeck etc or to simply expose
sensitive information like an api key only for the duration the program is executed!

The goal is to make exposing sensitive information short lived and confined to just the execution
of the desired program; because we export variables and run the program in a subshell, upon
exit those variables will no longer be available in your environment.

The other goal is to make switching configs quick and easy, if your managing many servers, environments,
or generally using a common tool with different profiles / settings, this can make switching
quick an easy!

TODO: asciidemo, psql, mysql, rd, tmux status line....

This is further secured / enhanced if you derive your values from a cli password manager
such as pass or gopass, then you can safely version control your shims!

e.g. in a configuration file for your shim, you can do like so with gopass:

```sh
export HOMEBREW_GITHUB_API_TOKEN="$(gopass homebrew-git-pat)"
``````


## How to create a program shim:

1. Within your desired shims directory, make a directory after your named program, e.g.
`mkdir mysql` and cd into it
the directory name will be used as your program name and will be accessible within your
`PATH` 

2. create a script named 'run', make executable and put your logic in there, logic can include
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

4. run `cx enable <your shim name>`, this will create a symlink for your shim and be accessible
    in your PATH

## How to change your shims configuration

```sh
cx <program> <config> 
```

e.g. if your shim program is named `mysql` and you have a
configuration named `staging` you'd changed to that config like so:

```sh
cx mysql staging # use staging config
cx mysql clear   # clear config, 
cx disable mysql # use normal 'mysql' in your PATH (bypassing shim)
```

You're file layout may look like so:

```text
my-shims
├── common                      <--- common includes (can configure with $CX_COMMON_DIR)
│   ├── csp
│   └── trap-handler
├── mysql
│   ├── config -> sandbox       <--- current config
│   ├── production
│   ├── run                     <--- current script / shim
│   ├── sandbox
│   ├── scratch
│   └── staging
├── psql
│   ├── analytics
│   ├── config -> operations    <--- current config
│   ├── operations
│   └── run                     <--- current script / shim

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
- common functions in lib
- asciinema demo
- tmux status line


## How to clear your programs config

```sh
cx <program> clear
```

    e.g.

```
cx mysql clear
cx disable mysql
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
#!/usr/bin/env bash

set -euo pipefail

# Bring in common functions and config
. <(cx --init)
. "${CX_COMMON_DIR}/trap-handler"
. "${CX_COMMON_DIR}/csp"

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

to use your shim:

```sh
cx enable psql
cx psql staging
psql # <- calls your shim script, which sets up values and runs 'cx_bin_wrap psql [args...]'
```
