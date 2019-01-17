#!/usr/bin/env bash

_join_by(){
    local -n array="${1}"
    local join_char="${2}"
    local -n result="${3}"

    local temp=""
    for value in ${array[@]}; do
        temp="${temp}${value}${join_char}"
    done

    result="${temp: :-${#join_char}}"
}

_docker_ps_ids(){
    local -n result="${1}"
    
    result=( $(sudo docker ps -a -q) ) 
}

_main(){
    local result
    local sep
    local arr

    echo "Get containers ids"
    _docker_ps_ids arr 
    _join_by arr " " result
    echo "${result}"

    echo "Deleting all"
    sudo docker rm ${result}
}

_main "$@"
