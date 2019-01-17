#!/usr/bin/env bash

### README ###
# You should use in functions prefix 'local_' for variables 
# which get value from arguments and you shouldn't use 
# this prefix for arguments. For preventing 'circular name reference' error. 
### ------ ###

# Exit script when command fails
set -o errexit
# Returns error from pipe `|` if any of the commands in the pipe fail 
# (normally just returns an error if the last fails)
set -o pipefail

# Function for grep arguments from user
_getArguments(){
    # All arguments
    local -n local_all_arguments="${1}"
    # Path to Jenkinsfile (pipeline)
    local -n local_path_jenkinsfile="${2}"
    # Job name
    local -n local_job_name="${3}"

    # -gt = '>'
    # array=("${array[@]:2}") - delete first and second element
    while [[ "${#local_all_arguments[@]}" -gt 0 ]]; do
        case "${local_all_arguments[0]}" in 
            -f|--file)
                local_path_jenkinsfile="${local_all_arguments[1]}"
                local_all_arguments=("${local_all_arguments[@]:2}")
                ;;
            -j|--job)
                local_job_name="${local_all_arguments[1]}"
                local_all_arguments=("${local_all_arguments[@]:2}")
                ;;
            -h|--help)
                echo '-f | --file Path to Jenkinsfile (pipeline)'
                echo '-j | --job  Job name'
                echo 'Set this enviroment variables for connection'
                echo 'JENKINS_CLI_SERVER_URL - Jenkins url address (with view)'
                echo 'JENKINS_CLI_USER_LOGIN - your login'
                echo 'JENKINS_CLI_USER_TOKEN - api token from /user/[user]/configure'
                exit 0    
                ;;
            *)
                echo "Invalid argument"
                exit 1
                ;;
        esac
    done
}

_getCurrentConfig(){
    # Parameters
    local -n local_server_url="${1}"
    local -n local_job_name="${2}"
    local -n local_user_login="${3}"
    local -n local_user_api_token="${4}"
    local -n local_local_config_name="${5}"

    # Save config to file (.tmpconfig.xml)
    curl -s "${local_server_url}/job/${local_job_name}/config.xml" \
        -u "${local_user_login}":"${local_user_api_token}" \
        > "${local_local_config_name}"
}

_updateTmpConfig(){
    # Function parameters
    local -n local_path_jenkinsfile=${1}
    local -n local_local_config_name=${2}
    
    # Init temporary new config
    local local_new_config_name=".tmpconfignew.xml"
    echo -n "" > "${local_new_config_name}"
    
    # Variables needed for loop to creating new config
    local num_lines_conf=$(wc -l < "${local_local_config_name}")
    num_lines_conf=$(( $num_lines_conf + 1 ))
    local num_cur_line=1
    local cur_line=""
    
    #Add to new config lines before tag <definition*
    while [[ "${num_cur_line}" != "${num_lines_conf}" ]];do
        cur_line=$(sed -n "${num_cur_line}p" ${local_local_config_name})
        echo "${cur_line}" >> "${local_new_config_name}"
        if echo "${cur_line}" | grep -o "<definition[^>]*>" >/dev/null; then 
            break
        fi
        num_cur_line=$(( $num_cur_line + 1))
    done

    #Add <script>.* line
    while [[ "${num_cur_line}" != "${num_lines_conf}" ]];do
        cur_line=$(sed -n "${num_cur_line}p" ${local_local_config_name})
        if echo "${cur_line}" | grep -o "[ ]*<script>" >/dev/null; then
            echo "${cur_line}" | grep -o "[ ]*<script>" | tr -d "\n" >> "${local_new_config_name}"
            break
        fi
        num_cur_line=$(( $num_cur_line + 1))
    done
    
    #Add Jenkinsfile
    echo -n "$(cat ${local_path_jenkinsfile})" >> "${local_new_config_name}"
    
    #Add </script> tage
    echo '</script>' >> "${local_new_config_name}"

    #Find end of inserting Jenkinsfile rest of the file
    while [[ "${num_cur_line}" != "${num_lines_conf}" ]];do
        cur_line=$(sed -n "${num_cur_line}p" ${local_local_config_name})
        if echo "${cur_line}" | grep -o "[ ]*</script>" >/dev/null; then
            num_cur_line=$(( $num_cur_line + 1))
            break
        fi
        num_cur_line=$(( $num_cur_line + 1)) 
    done

    # Add rest of the file
    while [[ "${num_cur_line}" != "${num_lines_conf}" ]];do
        cur_line=$(sed -n "${num_cur_line}p" ${local_local_config_name})
        echo "${cur_line}" >> "${local_new_config_name}"
        num_cur_line=$(( $num_cur_line + 1))
    done

    # Add last line
    echo -n "$(sed -n ${num_lines_conf}p ${local_local_config_name})" \
        >> "${local_new_config_name}"
    
    # Push new config
    cat "${local_new_config_name}" > "$local_local_config_name"
    rm "${local_new_config_name}"
}

_pushLocalConfig(){
    # Parameters
    local -n local_server_url="${1}"
    local -n local_job_name="${2}"
    local -n local_user_login="${3}"
    local -n local_user_api_token="${4}"
    local -n local_local_config_name="${5}"
    
    # Push local config to Jenkins
    curl -XPOST -s -k \
        -u "${local_user_login}":"${local_user_api_token}" \
        --data-binary @.tmpconfig.xml \
        "${local_server_url}/job/${local_job_name}/config.xml" 
}

_main(){

    ### Announce variables ###
    # All arguments from user
    local arguments=("$@")
    # Get sensitive data from environment variables
    local server_url="${JENKINS_CLI_SERVER_URL}"
    local user_login="${JENKINS_CLI_USER_LOGIN}"
    local user_api_token="${JENKINS_CLI_USER_TOKEN}"
    # User arguments
    local path_jenkinsfile
    local job_name
    # Config variables
    local local_config_name='.tmpconfig.xml'
    ### ------------------ ###

    ### Call functions ###
     _getArguments arguments path_jenkinsfile job_name
     _getCurrentConfig server_url job_name user_login user_api_token local_config_name
     _updateTmpConfig path_jenkinsfile local_config_name
     _pushLocalConfig server_url job_name user_login user_api_token local_config_name
    ### -------------- ###    
    
}

_main "$@"
