#!/usr/bin/env bash

# Settings
regex_validate_aws_region="^[a-z]{2}-[a-z]+-[[:digit:]]{1,2}$"

# Arrray's containing AWS targed accounts based on modified files
MODIFIED_FILES_PATH_GLOBAL=()
MODIFIED_FILES_PATH_CHINA=()


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
            if [[ ${MODIFIED_FILES_PATH_CHINA[@]} =~ $_aws_account_name ]]; then
                echo "AWS environment $_aws_account_name is already targeted for planning. Skipping"
            else
                MODIFIED_FILES_PATH_CHINA+=($_aws_account_name)
            fi
        else
            # Add AWS target account to be executed from GLOBAL self hosted runner
            if [[ ${MODIFIED_FILES_PATH_GLOBAL[@]} =~ $_aws_account_name ]]; then
                echo "AWS environment $_aws_account_name is already targeted for planning. Skipping"
            else
                MODIFIED_FILES_PATH_GLOBAL+=($_aws_account_name)
            fi
        fi
    else
        echo -e "\e[31m$current_file\e[0m does not appear to contain any region. Ignoring $string"
    fi

}

# Perform a reverse search by comparing the AWS accounts listed in accounts.json against the path of edited files
for file in ${ALL_CHANGED_FILES}; do
    aws_accounts_terragrunt_include $file
done



echo "${MODIFIED_FILES_PATH_GLOBAL[@]}"
echo "${MODIFIED_FILES_PATH_CHINA[@]}"

EXPORT "GLOBAL_RUNNER_AWS_TAARGET_ACCOUNT=${MODIFIED_FILES_PATH_GLOBAL[@]}" >> $GITHUB_OUTPUT
EXPORT "CHINA_RUNNER_AWS_TAARGET_ACCOUNT=${MODIFIED_FILES_PATH_GLOBAL[@]}" >> $GITHUB_OUTPUT