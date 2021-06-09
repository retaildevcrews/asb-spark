#!/bin/bash

# name of service principal
SP_NAME="http://github-action-dns"

# resource group of DNS Zone for the hack
DNS_ZONE_RG=TLD

# name of DNS Zone for the hack
DNS_ZONE_NAME=aks-sb.com

# create service principal and save credentials that will be saved to GitHub secret
AZURE_CREDENTIALS=$(az ad sp create-for-rbac -n $SP_NAME --skip-assignment --sdk-auth)

# fetch object id of service principal
SP_OBJECT_ID=$(az ad sp show --id $SP_NAME --query objectId -o tsv)

# fetch resource ID of DNS Zone
DNS_ZONE_ID=$(az network dns zone show -n $DNS_ZONE_NAME -g $DNS_ZONE_RG --query id -o tsv)

# add role assignment to allow service principal to manage dns records

# TODO:
#   look into more granular permissions for only manage `A` records. create task on board
#   These actions are probably a good starting point to try out.
#   https://docs.microsoft.com/en-us/azure/role-based-access-control/custom-roles-cli#create-a-custom-role
#   Microsoft.Network/dnszones/A/read
#   Microsoft.Network/dnszones/A/write

az role assignment create --role "DNS Zone Contributor" --assignee-object-id $SP_OBJECT_ID --assignee-principal-type "ServicePrincipal" --scope $DNS_ZONE_ID

# show user the data to put in the GitHub secret
echo "Copy the output below into a GitHub secret named 'AZURE_CREDENTIALS'"
echo "$AZURE_CREDENTIALS"
