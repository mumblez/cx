# shellcheck disable=SC2207,SC2010,SC2086
_cx_completion()
{
    local CX_BASE_CMDS CX_IGNORE_DIRS CX_IGNORE_FILES CX_IGNORE
    CX_SHIMS_DIR=${CX_SHIMS_DIR:-"${HOME}/shims"}
    CX_BIN_DIR=${CX_BIN_DIR:-"${HOME}/shims_bin"}
    CX_BASE_CMDS=("setup get enable disable list")
    CX_LIST_OPTIONS=("enabled disabled")
    CX_BIN_LINK="${CX_BIN_LINK:-run}"
    CX_CONFIG_LINK="${CX_CONFIG_LINK:-config}"
    CX_IGNORE_DIRS="bin|common"
    CX_IGNORE_FILES="cx|autocomplete.bash"
    CX_IGNORE="${CX_CONFIG_LINK}|${CX_BIN_LINK}|${CX_IGNORE_DIRS}|${CX_IGNORE_FILES}"

    local cur prev

    cur=${COMP_WORDS[COMP_CWORD]}
    prev=${COMP_WORDS[COMP_CWORD-1]}

    case ${COMP_CWORD} in
        1)
            COMPREPLY=($(compgen -W "${CX_BASE_CMDS[*]} $(cx list)" -- ${cur}))
            ;;
        2)
            if [[ $prev == "list" ]]; then COMPREPLY=($(compgen -W "${CX_LIST_OPTIONS[*]} $(cx list)" -- ${cur}))
            elif [[ $prev == "enable" ]]; then COMPREPLY=($(compgen -W "$(cx list disabled)" -- ${cur}))
            elif [[ $prev == "disable" ]]; then COMPREPLY=($(compgen -W "$(cx list enabled)" -- ${cur}))
            elif [[ "${CX_BASE_CMDS[*]}" =~ $prev ]]; then COMPREPLY=($(compgen -W "$(cx list)" -- ${cur}))
            else COMPREPLY=($(compgen -W "$(ls -1 "${CX_SHIMS_DIR}/${prev}" | grep -vE "($CX_IGNORE)")" -- ${cur}))
            fi
            ;;
        *)
            COMPREPLY=()
            ;;
    esac
}

complete -F _cx_completion cx
