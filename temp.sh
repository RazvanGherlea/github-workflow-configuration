#!/bin/bash

#[a-z]{2}-[a-z]+-\d{1,2}

string="management-china-prod/ap-east-1/app1/terragrunt.hcl"
regex_exp_region="^[a-z]{2}-[a-z]+-[[:digit:]]{1,2}$"
#echo $string | cut -d '/' -f 2

# Split string and validate that file belongs to a AWS account
_aws_account_name=$(echo $string | cut -d '/' -f 1)
_aws_region_name=$(echo $string | cut -d '/' -f 2)

# echo $_aws_region_name|grep -q $regex_exp_region
# echo $?

if [[ "$_aws_region_name" =~ $regex_exp_region ]]; then
    echo "$string is part of the $_aws_account_name AWS account in region $_aws_region_name"
else
    echo "$string does not appear to contain any region. Ignoring $string"
fi
