#!/bin/bash

# change to this directory
cd $(dirname $0)

# resource group of DNS Zone for the hack
DNS_ZONE_RG=TLD

# name of DNS Zone for the hack
DNS_ZONE_NAME=aks-sb.com

# if [ ! -f "dns-name.txt" ]
# then
#   exit
# fi

# if [ ! -f "public-ip-address.txt" ]
# then
#   exit
# fi

# team name to be used for dns record
# ASB_TEAM_NAME=$(cat dns-name.txt)

# public IP address of app gateway
# ASB_AKS_PIP=$(cat public-ip-address.txt)

if [ -z "$ASB_TEAM_NAME" ]
then
  echo "ASB_TEAM_NAME name is required"
  exit
fi

if [ -z "$ASB_AKS_PIP" ]
then
  echo "ASB_AKS_PIP is required"
  exit
fi

# create the dns record
az network dns record-set a add-record -g $DNS_ZONE_RG -z $DNS_ZONE_NAME -n $ASB_TEAM_NAME -a $ASB_AKS_PIP --query fqdn
