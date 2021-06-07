#!/bin/bash

set -e

# teamName is required
if [ -z "$1" ]
then
  echo Usage: ./setup.sh teamName
  exit 1
fi

# help
if [ "-h" == "$1" ] || [ "--help" == "$1" ]
then
  echo Usage: ./setup.sh teamName
  exit 0
fi

# check Azure login
if [ -z $(az ad signed-in-user show --query objectId -o tsv) ]
then
  echo Login to Azure first
  exit 1
fi

# change to this directory
cd $(dirname $0)

# save param as ASB_TEAM_NAME
export ASB_TEAM_NAME=$1

# set default domain name
if [ -z "$ASB_DNS_ZONE" ]
then
  export ASB_DNS_ZONE=aks-sb.com
fi
export ASB_DOMAIN=${ASB_TEAM_NAME}.${ASB_DNS_ZONE}

# set default shared cert values
if [ -z "$ASB_KV_NAME" ]
then
  export ASB_KV_NAME=kv-tld
fi

if [ -z "$ASB_CERT_NAME" ]
then
  export ASB_CERT_NAME=aks-sb
fi

# set default location
if [ -z "$ASB_LOCATION" ]
then
  export ASB_LOCATION=eastus2
fi

# set default geo redundant location for ACR
if [ -z "$ASB_GEO_LOCATION" ]
then
  export ASB_GEO_LOCATION=centralus
fi

# make sure the locations are different
if [ "$ASB_LOCATION" == "$ASB_GEO_LOCATION" ]
then
  echo ASB_LOCATION and ASB_GEO_LOCATION must be different regions
  echo Using paired regions is recommended
  exit 1
fi

# AAD admin group name
if [ -z "$ASB_CLUSTER_ADMIN_GROUP" ]
then
  export ASB_CLUSTER_ADMIN_GROUP=cluster-admins-$ASB_TEAM_NAME
fi

# github info for flux
if [ -z "$ASB_GIT_REPO" ]
then
  export ASB_GIT_REPO=$(git remote -v | cut -f 2 | cut -f 1 -d " " | head -n 1)

  if [ -z "$ASB_GIT_REPO" ]
  then
    echo Please cd to an ASB git repo
    exit 1
  fi
fi

if [ -z "$ASB_GIT_PATH" ]
then
  export ASB_GIT_PATH=gitops
fi

if [ -z "$ASB_GIT_BRANCH" ]
then
  export ASB_GIT_BRANCH=$(git status  --porcelain --branch | head -n 1 | cut -f 2 -d " " | cut -f 1 -d .)
fi


# don't allow main branch
if [ -z "$ASB_GIT_BRANCH" ] || [ "main" == "$ASB_GIT_BRANCH" ]
then
  echo Please create a branch for this cluster
  echo See readme for instructions
  exit 1
fi

# resource group names
if [ -z "$ASB_RG_CORE" ]
then
  export ASB_RG_CORE=rg-${ASB_TEAM_NAME}-core
fi

if [ -z "$ASB_RG_HUB" ]
then
  export ASB_RG_HUB=rg-${ASB_TEAM_NAME}-networking-hubs
fi

if [ -z "$ASB_RG_SPOKE" ]
then
  export ASB_RG_SPOKE=rg-${ASB_TEAM_NAME}-networking-spokes
fi

# export AAD env vars
export ASB_TENANT_ID=$(az account show --query tenantId -o tsv)

# continue on error
set +e

# create AAD cluster admin group
export ASB_CLUSTER_ADMIN_ID=$(az ad group create --display-name $ASB_CLUSTER_ADMIN_GROUP --mail-nickname $ASB_CLUSTER_ADMIN_GROUP --description "Principals in this group are cluster admins on the cluster." --query objectId -o tsv)

# add current user to cluster admin group
# you can ignore the exists error
az ad group member add -g $ASB_CLUSTER_ADMIN_ID --member-id $(az ad signed-in-user show --query objectId -o tsv)

set -e

# get *.onmicrosoft.com domain
export ASB_TENANT_TLD=$(az ad signed-in-user show --query 'userPrincipalName' -o tsv | cut -d '@' -f 2 | sed 's/\"//')

# create the resource groups
az group create -n $ASB_RG_HUB -l $ASB_LOCATION
az group create -n $ASB_RG_SPOKE -l $ASB_LOCATION
az group create -n $ASB_RG_CORE -l $ASB_LOCATION

# save env vars
./saveenv.sh -y

# deploy the network
az deployment group create -g $ASB_RG_HUB -f networking/hub-default.json -p location=${ASB_LOCATION}
export ASB_VNET_HUB_ID=$(az deployment group show -g $ASB_RG_HUB -n hub-default --query properties.outputs.hubVnetId.value -o tsv)

az deployment group create -g $ASB_RG_SPOKE -f networking/spoke-BU0001A0008.json -p location=${ASB_LOCATION} hubVnetResourceId="${ASB_VNET_HUB_ID}"
export ASB_NODEPOOLS_SUBNET_ID=$(az deployment group show -g $ASB_RG_SPOKE -n spoke-BU0001A0008 --query properties.outputs.nodepoolSubnetResourceIds.value -o tsv)

az deployment group create -g $ASB_RG_HUB -f networking/hub-regionA.json -p location=${ASB_LOCATION} nodepoolSubnetResourceIds="['${ASB_NODEPOOLS_SUBNET_ID}']"
export ASB_SPOKE_VNET_ID=$(az deployment group show -g $ASB_RG_SPOKE -n spoke-BU0001A0008 --query properties.outputs.clusterVnetResourceId.value -o tsv)

# grant executer permission to the key vault
az keyvault set-policy --certificate-permissions list get --object-id $(az ad signed-in-user show --query objectId -o tsv) -n $ASB_KV_NAME -g TLD
az keyvault set-policy --secret-permissions list get --object-id $(az ad signed-in-user show --query objectId -o tsv) -n $ASB_KV_NAME -g TLD

# create AKS
az deployment group create -g $ASB_RG_CORE \
  -f cluster-stamp.json \
  -n cluster-${ASB_TEAM_NAME} \
  -p  location=${ASB_LOCATION} \
      geoRedundancyLocation=${ASB_GEO_LOCATION} \
      asbTeamName=${ASB_TEAM_NAME} \
      asbDomain=${ASB_DOMAIN} \
      asbDnsZone=${ASB_DNS_ZONE} \
      targetVnetResourceId=${ASB_SPOKE_VNET_ID} \
      clusterAdminAadGroupObjectId=${ASB_CLUSTER_ADMIN_ID} \
      k8sControlPlaneAuthorizationTenantId=${ASB_TENANT_ID} \
      appGatewayListenerCertificate=$(az keyvault secret show --vault-name $ASB_KV_NAME -n $ASB_CERT_NAME --query "value" -o tsv | tr -d '\n') \
      aksIngressControllerCertificate="not used" \
      aksIngressControllerKey="not used"

# Remove user's permissions from shared keyvault. It is no longer needed after this step.
az keyvault delete-policy --object-id $(az ad signed-in-user show --query objectId -o tsv) -n $ASB_KV_NAME

# get cluster name
export ASB_AKS_NAME=$(az deployment group show -g $ASB_RG_CORE -n cluster-${ASB_TEAM_NAME} --query properties.outputs.aksClusterName.value -o tsv)

# Get the public IP of our App gateway
export ASB_AKS_PIP=$(az network public-ip show -g $ASB_RG_SPOKE --name pip-BU0001A0008-00 --query ipAddress -o tsv)

# Add "A" record for the app gateway IP to the public DNS Zone
az network dns record-set a add-record -a $ASB_AKS_PIP -n $ASB_TEAM_NAME -g TLD -z aks-sb.com

# Get the AKS Ingress Controller Managed Identity details.
export ASB_TRAEFIK_RESOURCE_ID=$(az deployment group show -g $ASB_RG_CORE -n cluster-${ASB_TEAM_NAME} --query properties.outputs.aksIngressControllerPodManagedIdentityResourceId.value -o tsv)
export ASB_TRAEFIK_CLIENT_ID=$(az deployment group show -g $ASB_RG_CORE -n cluster-${ASB_TEAM_NAME} --query properties.outputs.aksIngressControllerPodManagedIdentityClientId.value -o tsv)
export ASB_POD_MI_ID=$(az identity show -n podmi-ingress-controller -g $ASB_RG_CORE --query principalId -o tsv)

# save env vars
./saveenv.sh -y

az keyvault set-policy --certificate-permissions get --object-id $ASB_POD_MI_ID -n $ASB_KV_NAME
az keyvault set-policy --secret-permissions get --object-id $ASB_POD_MI_ID -n $ASB_KV_NAME

# config traefik
export ASB_INGRESS_CERT_NAME=aks-sb-crt
export ASB_INGRESS_KEY_NAME=$ASB_CERT_NAME

rm -f gitops/ingress/02-traefik-config.yaml
cat templates/traefik-config.yaml | envsubst  > gitops/ingress/02-traefik-config.yaml
rm -f gitops/ngsa/ngsa-ingress.yaml
cat templates/ngsa-ingress.yaml | envsubst  > gitops/ngsa/ngsa-ingress.yaml

# update flux.yaml
rm -f flux.yaml
cat templates/flux.yaml | envsubst  > flux.yaml

# get AKS credentials
az aks get-credentials -g $ASB_RG_CORE -n $ASB_AKS_NAME

# rename context for simplicity
kubectl config rename-context $ASB_AKS_NAME $ASB_TEAM_NAME
