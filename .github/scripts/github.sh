#!/usr/bin/env bash

# Arrray containing AWS targed accounts based on modified files
MODIFIED_FILES_PATH=()

# Validate each edited file and decide where terragrunt should be executed
# This helps to control PR execution time 
function aws_accounts_terragrunt_include () {
    # Select AWS account names and exclude china
    if $(echo $SET_RUNNER_CHINA); then
        for aws_account_name in `jq -r 'keys[]' $JSON_ACC_LIST_PATH|grep -v china`; do
            if [[ $1 == *"$aws_account_name"* ]]; then
                echo "$1 is part of the accound $aws_account_name"
                MODIFIED_FILES_PATH+=($aws_account_name)
            fi
        done
    elif
        for aws_account_name in `jq -r 'keys[]' $JSON_ACC_LIST_PATH|grep china`; do
            if [[ $1 == *"$aws_account_name"* ]]; then
                echo "$1 is part of the accound $aws_account_name"
                MODIFIED_FILES_PATH+=($aws_account_name)
            fi
    fi
}

# Execute terragrunt plan simultaneously on the target aws accounts 
function trigger_terragrunt_cli () {

    cat <<__USAGE__

        ########## Terragrunt Operations #############################################

        TERRAGRUNT PLAN target environments: ${MODIFIED_FILES_PATH[@]}

        ################################################################################

__USAGE__


    echo "terragrunt plan --terragrunt-include-dir ${MODIFIED_FILES_PATH[@]}"
}

# Perform a reverse search by comparing the AWS accounts listed in accounts.json against the path of edited files
for file in ${ALL_CHANGED_FILES}; do
    aws_accounts_terragrunt_include $file
done

# Exit the pipeline with success if there are no operations to be done in a particular AWS account
if [[ -z "${MODIFIED_FILES_PATH[@]}" ]]; then
    echo "No file belonging to any aws account has been edited"
else
    echo "${MODIFIED_FILES_PATH[@]}"
    trigger_terragrunt_cli
fi