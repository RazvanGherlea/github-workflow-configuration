#!/usr/bin/env bash

# Settings
regex_validate_aws_region="^[a-z]{2}-[a-z]+-[[:digit:]]{1,2}$"

# Arrray's containing AWS targed accounts based on modified files
MODIFIED_FILES_PATH_GLOBAL=()
MODIFIED_FILES_PATH_CHINA=()

green() {
    echo -e "\e[32m${1}\e[0m"
}


# Iterate through the changed files and select target AWS accounts for execution (uniq)
function aws_accounts_terragrunt_include () {
    # Determine if file felongs to China AWS Accounts
    current_file=$1

    # Split string and validate that file belongs to a AWS account
    _aws_account_name=$(echo $current_file | cut -d '/' -f 1)
    _aws_region_name=$(echo $current_file | cut -d '/' -f 2)


    # Select the AWS accounts where to execute terragrunt plan
    if [[ "$_aws_region_name" =~ $regex_validate_aws_region ]]; then
        echo -e "\e[32m$current_file\e[0m is part of the $_aws_account_name AWS account in region $_aws_region_name"
        if [[ $_aws_account_name == *china* ]]; then
            # Add AWS target account to be executed from CHINA self hosted runner
            MODIFIED_FILES_PATH_CHINA+=($_aws_account_name)
        else
            # Add AWS target account to be executed from GLOBAL self hosted runner
            MODIFIED_FILES_PATH_GLOBAL+=($_aws_account_name)
        fi
    else
        echo -e "\e[31m$current_file\e[0m does not appear to contain any region. Ignoring $string"
    fi

    # Select AWS account names and exclude china
    # if [[ $(echo $SET_RUNNER_CHINA) == true ]]; then
    #     for aws_account_name in `jq -r 'keys[]' $JSON_ACC_LIST_PATH|grep -i china`; do
    #         if [[ $1 == *"$aws_account_name"* ]]; then
    #             MODIFIED_FILES_PATH+=($aws_account_name)
    #         fi
    #     done
    # else
    #     for aws_account_name in `jq -r 'keys[]' $JSON_ACC_LIST_PATH|grep -v china`; do
    #         if [[ $1 == *"$aws_account_name"* ]]; then
    #             MODIFIED_FILES_PATH+=($aws_account_name)
    #         fi
    #     done
    # fi
    # echo "::set-output name=trigger_china_pipeline::true"

}

# Execute terragrunt plan simultaneously on the target aws accounts 
function trigger_terragrunt_cli () {

    cat <<__USAGE__

        ########## $(echo -e "\e[31mTerragrunt Operations\e[0m") #############################################

        TERRAGRUNT PLAN target environments: $(echo -e "\e[32m${MODIFIED_FILES_PATH[@]}\e[0m")

        ################################################################################

__USAGE__


    echo "terragrunt plan --terragrunt-include-dir ${MODIFIED_FILES_PATH[@]}"
}

# Perform a reverse search by comparing the AWS accounts listed in accounts.json against the path of edited files
for file in ${ALL_CHANGED_FILES}; do
    aws_accounts_terragrunt_include $file
done

# # Exit the pipeline with success if there are no operations to be done in a particular AWS account
# if [[ -z "${MODIFIED_FILES_PATH[@]}" ]]; then
#     echo "No file belonging to any aws account has been edited"
# else
#     echo "${MODIFIED_FILES_PATH[@]}"
#     trigger_terragrunt_cli
# fi

#echo "trigger_china_pipeline=false" >> $GITHUB_OUTPUT

echo $MODIFIED_FILES_PATH_GLOBAL[@]
echo $MODIFIED_FILES_PATH_CHINA[@]