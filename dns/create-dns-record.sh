#!/bin/bash

# change to this directory
cd $(dirname $0)

# resource group of DNS Zone for the hack
DNS_ZONE_RG=TLD

# name of DNS Zone for the hack
DNS_ZONE_NAME=aks-sb.com

# TODO: check if files exist is keeping the txt file option for passing configs

# team name to be used for dns record
# TODO:
#   get team name from somewhere.
#   currently planning on using a txt file that is checked into the branch. looking for other options.
ASB_TEAM_NAME=$(cat dns-name.txt)

# public IP address of app gateway
# TODO:
#   get public ip address from somewhere.
#   currently planning on using a txt file that is checked into the branch. looking for other options.
APP_GW_PIP=$(cat public-ip-address.txt)

if [ -z "$ASB_TEAM_NAME" ]
then
  echo "ASB_TEAM_NAME name is required"
  exit
fi

if [ -z "$APP_GW_PIP" ]
then
  echo "APP_GW_PIP is required"
  exit
fi

# create the dns record
az network dns record-set a add-record -g $DNS_ZONE_RG -z $DNS_ZONE_NAME -n $ASB_TEAM_NAME -a $APP_GW_PIP --query fqdn
