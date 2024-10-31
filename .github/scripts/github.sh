#!/usr/bin/env bash

#### Settings
# Regex validating the region AWS proprietary naming convention
regex_validate_aws_region="^[a-z]{2}-[a-z]+-[[:digit:]]{1,2}$"
# Tag used for triggering Terragrunt with run-all parameter in each target AWS target Account
RUNALL_TAG='[run-all]'



# Arrray's containing AWS targed accounts based on modified files
MODIFIED_FILES_PATH_GLOBAL=()
MODIFIED_FILES_PATH_CHINA=()
validation_empty_array=()


terra_ops_arg_construct() {
    # Validates if the trigger depth should be on the whole AWS Account level or per resource level
    if [[ $COMMIT_MESSAGE_TRIGGER =~ "$RUNALL_TAG" ]]; then
        return 0
    else
        return 1
    fi
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

        # INFO
        echo -e "\e[32m$current_file\e[0m is part of the $_aws_account_name AWS account in region $_aws_region_name"
        # Construct the string for comparement. If run-all used it will switch to aws account level, if not it will switch to target resource path
        dynamic_path_select=$(terra_ops_arg_construct && echo $_aws_account_name  || echo $current_file )

        if [[ $_aws_account_name == *china* ]]; then
            # Add AWS target account to be executed from CHINA self hosted runner #TODO this has to be updated because it skipps direct paths but works with full run-all parameter
            if [[ ${MODIFIED_FILES_PATH_CHINA[@]} =~ $dynamic_path_select ]]; then
                echo "AWS environment $dynamic_path_select is already targeted for planning. Skipping"
            else
                # Define the depthness of the terragrunt plan command executed based on a string in the --> git Commit <-- message 
                MODIFIED_FILES_PATH_CHINA+=($dynamic_path_select)
            fi
        else
            # Add AWS target account to be executed from GLOBAL self hosted runner
            if [[ ${MODIFIED_FILES_PATH_GLOBAL[@]} =~ $dynamic_path_select ]]; then
                echo "AWS environment $dynamic_path_select is already targeted for planning. Skipping"
            else
                # Define the depthness of the terragrunt plan command executed based on a string in the --> git Commit <-- message 
                MODIFIED_FILES_PATH_GLOBAL+=($dynamic_path_select)
            fi
        fi
    else
        echo -e "\e[31m$current_file\e[0m does not appear to contain any region. Ignoring $string"
    fi

}

# ALL_CHANGED_FILES=(
#     '.github/scripts/github.sh' 
#     '.github/workflows/pr.yaml'
#     'management-global-prod/ap-east-1/app1/terragrunt.hcl'
#     'management-global-prod/eu-central-1/app1/terragrunt.hcl'
#     'management-china-prod/us-east-1/app1/terragrunt.hcl'
# )

# Perform a reverse search by comparing the AWS accounts listed in accounts.json against the path of edited files
for file in ${ALL_CHANGED_FILES}; do
    aws_accounts_terragrunt_include $file
done

# echo "${ALL_CHANGED_FILES[@]}"

# for file in ${ALL_CHANGED_FILES[@]}; do
#     aws_accounts_terragrunt_include $file
# done


echo "${MODIFIED_FILES_PATH_GLOBAL[@]}"
echo "${MODIFIED_FILES_PATH_CHINA[@]}"

echo "GLOBAL_RUNNER_AWS_TARGET_ACCOUNT=${MODIFIED_FILES_PATH_GLOBAL[@]}" >> $GITHUB_OUTPUT
echo "CHINA_RUNNER_AWS_TARGET_ACCOUNT=${MODIFIED_FILES_PATH_CHINA[@]}" >> $GITHUB_OUTPUT
echo "validation_empty_array=${validation_empty_array[@]}" >> $GITHUB_OUTPUT