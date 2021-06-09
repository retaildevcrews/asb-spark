#!/bin/bash

# change to this directory
cd $(dirname $0)

# resource group of DNS Zone for the hack
DNS_ZONE_RG=TLD

# name of DNS Zone for the hack
DNS_ZONE_NAME=aks-sb.com

# TODO:
#   exit early if either ip address or name config is missing

# team name to be used for dns record
# TODO:
#   get team name from somewhere.
#   currently planning on using a txt file that is checked into the branch.
ASB_TEAM_NAME=gh-actions-test-4

# public IP address of app gateway
# TODO:
#   get public ip address from somewhere.
#   currently planning on using a txt file that is checked into the branch.
APP_GW_PIP=0.0.0.0

# TODO: exit early if either "APP_GW_PIP" or "ASB_TEAM_NAME" variable is empty

# create the dns record
az network dns record-set a add-record -g $DNS_ZONE_RG -z $DNS_ZONE_NAME -n $ASB_TEAM_NAME -a $APP_GW_PIP --query fqdn
