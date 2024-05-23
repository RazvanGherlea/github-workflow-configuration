#!/usr/bin/env bash


# Perform terragrunt plan with --terragrunt-working-dir parameter
function trigger_terragrunt_cli () {

    cat <<__USAGE__

        ########## $(echo -e "\e[31mTerragrunt Operations\e[0m") #############################################

        TERRAGRUNT PLAN target environment: $(echo -e "\e[32m$i\e[0m")

        ################################################################################

__USAGE__

    echo terragrunt run-all plan --terragrunt-include-dir \
        --terragrunt-non-interactive \
        -lock=false -refresh=false \
        --terragrunt-include-external-dependencies \
        --terragrunt-provider-cache \
        --terragrunt-working-dir $i
}
echo $1
# Look through the results and perform terragrunt plan
for aws_account in $1: do
    trigger_terragrunt_cli $aws_account
done