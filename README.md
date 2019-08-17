# cx

Context Switcher, switch configs, settings, profiles instantly for any program
cx is a tool that acts as a shim to allow context switching; to provide different
configurations to a common program, e.g. mysql, psql, rd etc or to simply expose
sensitive information like an api key only for the duration the program is executed!

The goal is to make exposing sensitive information short lived and confined to just the execution
of the desired program; because we export variables and run the program in a subshell, upon
exit those variables will no longer be available in your environment.

The other goal is to make switching configs quick and easy, if your managing many servers, environments,
or generally using a common tool with different profiles / settings, this can make switching
quick an easy!!

[![asciicast](https://asciinema.org/a/u9VXl6bkamjB0vSnVC1zpPtYx.png)](https://asciinema.org/a/u9VXl6bkamjB0vSnVC1zpPtYx)

This is further secured / enhanced if you derive your values from a cli password manager
such as pass or gopass, then you can safely version control your shims!

e.g. in a configuration file for your shim, you can do like so with gopass:

```sh
export HOMEBREW_GITHUB_API_TOKEN="$(gopass homebrew-git-pat)"
``````


## How to create a shim:

1. Within your desired shims directory, make a directory after your named program, e.g.
`mkdir mysql` and cd into it
the directory name will be used as your program name and will be accessible within your
`PATH` 

2. create a script named `run`, make executable and put your logic in there, logic can include
    - Pulling sensitive info out of [go]pass (if you don't want to put it in your configs clear text)
    - Setting config variables, e.g. host, username, password, project, instance....
    - Export the variables before calling the real program, e.g. 'mysql'
    - include `. <(cx --init)`, takes care of:
        - sourcing your current config
        - amending PATH to exclude cx bin dir (so your real command is now longer shadowed)
    - run your command as you normally would, e.g. `mysql <args>...`


3. create your various configurations, e.g. for different environments, instances, projects, dbs, etc..
    name then anything you want, except `config` (that will be the symlink to the desired configuration)

4. run `cx enable <shim>`, this will create a symlink for your shim and be accessible
    in your PATH

## How to change your shims configuration

```sh
cx <shim> <config> 
```

e.g. if your shim program is named `mysql` and you have a
configuration named `staging` you'd change the config like so:

```sh
cx mysql staging    # change context to staging config
cx mysql production # change context to production config
cx mysql clear      # clear config (deletes the symlink to the config), 
cx disable mysql    # disable symlink in your path (bypassing shim)
```

You're file layout may look like so:

```text
my-shims
├── common                      <--- common includes (can configure with $CX_COMMON_DIR)
│   └── mysql
│       └── init                <--- common values automatically sourced in as part of cx --init (after config)
│   ├── csp 
│   └── trap-handler
├── mysql
│   ├── config -> sandbox       <--- current context
│   ├── production
│   ├── sandbox
│   ├── scratch
│   ├── staging
│   └── run                     <--- shim script
└── psql
    ├── config -> staging       <--- current context
    ├── production
    ├── staging
    └── run                     <--- shim script

```
The 'current context' / config symlink gets created when you change context with `cx <shim> <config>`

## TODO: document
- asciinema demo

## How to clear your programs config

```sh
cx <shim> clear
```

    e.g.

```
cx mysql clear
cx disable mysql
```

## Example: creating a shim for postgres psql tool

in your base shims directory:

```sh
mkdir psql
cd psql
```
    
create a config named anything other than `config` (or whatever you set `config_link` to)

```sh
PGPASSWORD=myPass       # or $(gopass postgres/staging/db-1)
PGUSER=myUser           # or $(gopass postgres/staging/db-1 user) 
PGHOST=1.2.3.4:5432     # or $(gopass postgres/staging/db-1 host)
```

create your `run` script (and make executable), or symlink to a real script

```sh
#!/usr/bin/env bash

set -euo pipefail

# Bring in common functions and config
. <(cx --init) # sources current config and common init (if exists), then amends PATH so real command can be called
. "${CX_COMMON_DIR}/trap-handler"
. "${CX_COMMON_DIR}/csp"
#. "${CX_COMMON_DIR}/any/other/common/include"

# Validate we have the tools
cx_validate_tools gopass cloud_sql_proxy psql grep

# Start cloud_sql_proxy and wait for it to be ready
csp_start "$CSP_INSTANCE" "$SOCKET_DIR"

# launch psql
psql -w "$@"

```

to use your shim:

```sh
cx enable psql
cx psql staging
psql # <- calls your shim script, which sets up values and runs the real psql in your PATH (bypassing the shim)
cx psql production
psql # now you're using the production config!
```

# Install / Configuration

```sh
./cx init
```
The above command sets up a base config directory at `~/.config/cx`
contains:
- `bin/` - directory where symlinks to your shim get created when you `cx enable <shim>`
- `cxrc` - default settings, can be overriden with environment variables.

Follow the instructions, the last remaining steps are to :
- copy `cx` to somewhere in your `PATH`, e.g. `/usr/local/bin`
- source in autocomplete in your shells rc - `. <(cx --autocomplete)`
- prefix your `PATH` with your `~/.config/cx/bin`, this should be first in your `PATH` as we intentionally want to shadow real commands which are further down in your `PATH`, you may already have `PATH` modifications in your .bashrc / .bash_profile, try to add this step at the end!
- override your shims directory, either set `shims_dir` in ~/.config/cx/cxrc or export in your shells rc, e.g. - `export CX_SHIMS_DIR=~/repos/my-shims`
- override your common directory if you want it separate to a subdirectory of your shims dir, either set `common_dir` in ~/.config/cx/cxrc or export in your shells rc, e.g. - `export CX_COMMON_DIR=~/repos/my-shims-common`


# How it works

Because we ensure cx's bin_dir is first in your `PATH` we intercept the command with our shim.

In our shim script we initialise with `. <(cx --init)` which does the following:
- sources your shim's current context / config
- sources your shim's common config/include if it exists - `$CX_COMMON_DIR/config/<shim>/init`
- amends `PATH` to exclude cx's bin_dir
- the rest of the shim is logic unique to the command you want to run

# Recommendations
- [keybase](https://keybase.io) - securely host git repos (like your shims) and setup your pgp / gpg keys
- [gopass](https://www.gopass.pw/) - git version control and gpg encrypt your passwords and access them programmatically

## Adding context information to your tmux status line
in your `.tmux.conf`, for your `status-right` value, you can insert commands using the #(shell cmd) syntax e.g.

(showing the context value (current config) for mysql, rd and psql)
```text
RD:#(cx get rd) MYSQL:#(cx get mysql) PSQL:#(cx get psql)
```
optionally set the colours, e.g.
```text
#[fg=colour48,bg=colour238]#(cx get mysql)
```

