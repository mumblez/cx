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

        export HOMEBREW_GITHUB_API_TOKEN=\"\$(gopass homebrew-git-pat)\"


    How to create a program shim:
    =============================

    1. Within cx base directory, make a directory after your named program, e.g.

        'mkdir mysql' and cd into it
        the directory name will be used as your program name and will be accessible within your PATH
        we will shadow the program if it already exists in your path, to shadow you must ensure
        CX_BIN_DIR is in your path earlier than your other paths (set it at the beginning!)

    2. create a script named 'run', make executable and put your logic in there, logic shoud include
        - Pulling sensitive info out of [go]pass (if you don't want to put it in your configs clear text)
        - Setting config variables, e.g. host, username, password, project, instance....
        - Export the variables before calling the real program, e.g. 'mysql'
        - prefix your final command with 'cx_bin_wrap', e.g. 'cx_bin_wrap mysql --defaults-file=<(echo \$CONFIG)'
            - our 'cx_bin_wrap' will amend PATH just before execution so that the real command is 
                executed (later in your PATH)
            - detect how the command is invoked and handle appropriately, e.g.:
                - 'echo \"use somedb; select * from sometable;\" | mysql' # Piped content
                - 'mysql -v'                                            # just regular invocation


    3. create your various configurations, e.g. for different environments, instances, projects, dbs, etc..
        name then anything you want, except 'config' (that will be the symlink to the desired configuration)

    4. run 'cx setup', this will create symlinks for each shim in a directory in your PATH, e.g. 
        '\$CX_BIN_DIR/' (ensure this directory is in your PATH, ideally at the beginning!)


    How to change your program's configuration
    ==========================================

        cx <program> <config> 
    
    e.g. if your shim program is named 'mmysql' and you have a
    configuration named 'staging' you'd changed to that config like so:

        cx mmysql staging

    You're file layout may look like so:

        -cx/
         |-mmysql/
            |-staging
            |-production
            |-run
            |-config->staging

    the config symlink gets created when you 'cx mmysql staging', this is what you 'source' in
    your 'run' script, but use the 'cx_get_config' function so it can return the real path!


    How to clear your programs config
    =================================

        cx <program> clear

        e.g.

        cx mmysql clear


    Example: creating a shim for postgres psql tool
    ==================================

    in your cx base directory:

        mkdir ppsql
        
    cd into your shim directory and create a config named anything other than 'config'

        vim staging
        PGPASSWORD=myPass       # or \$(gopass postgres/staging/db-1)
        PGUSER=myUser           # or \$(gopass postgres/staging/db-1 user) 
        PGHOST=1.2.3.4:5432     # or \$(gopass postgres/staging/db-1 host)

    create your 'run' script (and make executable)

        vim run
        #!/usr/bin/bash

        ...
        source \"\${CX_BASE_DIR}/common/lib\"
        source \"\$(cx_get_config)\"
        # if you want to shadow an existing program name without using a unique name, we need to 
        # remove the \$CX_BASE_DIR from PATH, we can do that with a helper function:
        # 
        #    cx_path_exclude
        
        ...
        
        export PGUSER PGHOST PGPASSWORD  # or export in your config
        psql -w 

