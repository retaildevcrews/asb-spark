#!/bin/bash

# resource group of DNS Zone for the hack
DNS_ZONE_RG=TLD

# name of DNS Zone for the hack
DNS_ZONE_NAME=aks-sb.com

# team name to be used for dns record
# TODO:
#   read team name from txt file in branch
ASB_TEAM_NAME=gh-actions-test

# public IP address of app gateway
# TODO:
#   exit early if ip address file does not exist
#   read PIP from a txt file in the branch.
#   assuming this is created by the setup.sh script and the user followed the rest of the instructions in the readme
APP_GW_PIP=0.0.0.0

# TODO: exit early if "APP_GW_PIP" is empty

# TODO:
#   planning on using https://github.com/marketplace/actions/azure-cli-action
#   assuming runner of this script has already authenticated
#   in this case, will use the login feature of the azure cli action with the credentials created in the setup script

# create the dns record
az network dns record-set a add-record -g $DNS_ZONE_RG -z $DNS_ZONE_NAME -n $ASB_TEAM_NAME -a $APP_GW_PIP
