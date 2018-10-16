# Example shims

Ideally you'd make your own repository to host your shims and common includes

Examples assume gopass is setup, if you want to use these shims you only have to
edit the GPENTRY variable in the configs to your own personal path and export CX_SHIMS_DIR=/path/to/this/directory

Some example configs just have plain text values, in configuring for yourself you should prefer
to query / pull these values out from a password manager or some cli process to query / decrypt values.

e.g. for strings / values
SOME_TOKEN="$(pass path/to/some/token)"

e.g. for file contents:

```sh


read -r -d'\0' CRED_FILE <<EOF
$(gopass bin cat path/to/some/file/contents)
\0
EOF
# for a more complete example, see the mysql shim where we wrap the connection 
# info and pass this as `mysql --defaults-file=<(echo "$CON")`

my-cmd -credentials_file <(echo "$CRED_FILE")

```

Another way to pass file contents is to use bash builtin `mapfile` (but you lose compatibility with bash 3.2 on macs)

```sh
mapfile -t MY_CREDS_FILE < <(gopass bin cat path/to/some/creds/file)

my-cmd -credentials_file <(printf "%s\n", "${MY_CREDS_FILE[@]}")
```
