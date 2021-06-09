# AKS Secure Baseline Hack

> Welcome to the Patterns and Practices (PnP) AKS Secure Baseline (ASB) hack!

- The Patterns and Practices AKS Secure Baseline repo is located [here](https://github.com/mspnp/aks-secure-baseline)
  - This repo is a summarization specifically for the hack and `should not be used for production deployments`
  - Please refer to the PnP repo as the `upstream repo`

## Filing Bugs

> Please capture any bugs, issues or ideas on the `GitHub Board`

## Before Deploying ASB

- go to [idweb](https://idweb/) to setup a security group (requires VPN)
- create a security group
  - mail-enabled is optional
  - do not use spaces in the name
- add yourself and your team to the security group
- AAD propogation can take up to 30 minutes

## Deploying ASB

### Create Codespace

- The `AKS Secure Baseline` repo for the hack is at [github/retaildevcrews/asb-spark](https://github.com/retaildevcrews/asb-spark)
- Open this repo in your web browser
- Create a new `Codespace` in this repo
  - If the `fork option` appears, you need to request permission to the repo
  - Do not choose fork

```bash


# login to the Azure subscription for the hack
az login -t $ASB_TENANT_ID

# verify the correct subscription - bartr-cloudatx-asb
az account show

# install kubectl and kubelogin
sudo az aks install-cli

# set your security group name (created above); replace [YourSecurityGroupName] before running
export ASB_CLUSTER_ADMIN_GROUP=[YourSecurityGroupName]

# verify your security group membership
az ad group member list -g $ASB_CLUSTER_ADMIN_GROUP  --query [].mailNickname -o table

```

### Set Team Name

> Team Name is very particular and won't fail for about an hour ...
> we recommend youralias1 (not first.last)

```bash

#### set the team name
export ASB_TEAM_NAME=[starts with a-z, [a-z,0-9], max length 8]

# make sure the resource group doesn't exist
az group list -o table | grep $ASB_TEAM_NAME

# make sure the branch doesn't exist
git branch -a | grep $ASB_TEAM_NAME

# if either exists, choose a different team name and try again

```

### Create git branch

> Do not PR a `cluster branch` into main

```bash

# create a branch for your cluster
git checkout -b $ASB_TEAM_NAME
git push -u origin $ASB_TEAM_NAME

```

### Setup AKS Secure Baseline

> This section takes 45 - 60 minutes to complete

#### Initial Setup

```bash

# validate team name is set up
echo $ASB_TEAM_NAME

# verify the correct subscription
az account show

# check certs
echo $APP_GW_CERT
echo $INGRESS_CERT
echo $INGRESS_KEY

# set default location
export ASB_LOCATION=eastus2

# set default geo redundant location for ACR
# ASB_LOCATION and ASB_GEO_LOCATION must be different regions
export ASB_GEO_LOCATION=centralus

# run the saveenv.sh script at any time to save ASB_* variables to ~/ASB_TEAM_NAME.asb.env
./saveenv.sh

# if your terminal environment gets cleared, you can source the file to reload the environment variables
# source ~/${ASB_TEAM_NAME}.asb.env

```

#### AAD

````bash

# verify AAD admin group name
echo $ASB_CLUSTER_ADMIN_GROUP

# get AAD cluster admin group
export ASB_CLUSTER_ADMIN_ID=$(az ad group show -g $ASB_CLUSTER_ADMIN_GROUP --query objectId -o tsv)
echo $ASB_CLUSTER_ADMIN_ID

````

#### Git Setup

```bash

# set git repo
export ASB_GIT_REPO=$(git remote -v | cut -f 2 | cut -f 1 -d " " | head -n 1)
export ASB_GIT_PATH=gitops

# set git branch
# don't use main branch
export ASB_GIT_BRANCH=$(git status  --porcelain --branch | head -n 1 | cut -f 2 -d " " | cut -f 1 -d .)

```

#### Set variables for deployment

```bash

# set default domain name
export ASB_DNS_ZONE=aks-sb.com
export ASB_DOMAIN=${ASB_TEAM_NAME}.${ASB_DNS_ZONE}

# resource group names
export ASB_RG_CORE=rg-${ASB_TEAM_NAME}-core
export ASB_RG_HUB=rg-${ASB_TEAM_NAME}-networking-hub
export ASB_RG_SPOKE=rg-${ASB_TEAM_NAME}-networking-spoke

# export AAD env vars
export ASB_TENANT_ID=$(az account show --query tenantId -o tsv)

# save env vars
./saveenv.sh -y

```

#### Create Resource Groups

```bash

# create the resource groups
az group create -n $ASB_RG_HUB -l $ASB_LOCATION
az group create -n $ASB_RG_SPOKE -l $ASB_LOCATION
az group create -n $ASB_RG_CORE -l $ASB_LOCATION

```

#### Setup Network

```bash
# this section takes 30-45 minutes to complete

# create hub network
az deployment group create -g $ASB_RG_HUB -f networking/hub-default.json -p location=${ASB_LOCATION}
export ASB_VNET_HUB_ID=$(az deployment group show -g $ASB_RG_HUB -n hub-default --query properties.outputs.hubVnetId.value -o tsv)

# create spoke network
az deployment group create -g $ASB_RG_SPOKE -f networking/spoke-BU0001A0008.json -p location=${ASB_LOCATION} hubVnetResourceId="${ASB_VNET_HUB_ID}"
export ASB_NODEPOOLS_SUBNET_ID=$(az deployment group show -g $ASB_RG_SPOKE -n spoke-BU0001A0008 --query properties.outputs.nodepoolSubnetResourceIds.value -o tsv)

# create Region A hub network
az deployment group create -g $ASB_RG_HUB -f networking/hub-regionA.json -p location=${ASB_LOCATION} nodepoolSubnetResourceIds="['${ASB_NODEPOOLS_SUBNET_ID}']"
export ASB_SPOKE_VNET_ID=$(az deployment group show -g $ASB_RG_SPOKE -n spoke-BU0001A0008 --query properties.outputs.clusterVnetResourceId.value -o tsv)

# save env vars
./saveenv.sh -y

```

```bash

# validate env vars
echo $ASB_VNET_HUB_ID
echo $ASB_NODEPOOLS_SUBNET_ID
echo $ASB_SPOKE_VNET_ID

```

#### Setup AKS

```bash

# create AKS
az deployment group create -g $ASB_RG_CORE \
  -f cluster-stamp.json \
  -n cluster-${ASB_TEAM_NAME} \
  -p location=${ASB_LOCATION} \
     geoRedundancyLocation=${ASB_GEO_LOCATION} \
     asbTeamName=${ASB_TEAM_NAME} \
     asbDomain=${ASB_DOMAIN} \
     asbDnsZone=${ASB_DNS_ZONE} \
     targetVnetResourceId=${ASB_SPOKE_VNET_ID} \
     clusterAdminAadGroupObjectId=${ASB_CLUSTER_ADMIN_ID} \
     k8sControlPlaneAuthorizationTenantId=${ASB_TENANT_ID} \
     appGatewayListenerCertificate=${APP_GW_CERT} \
     aksIngressControllerCertificate="$(echo $INGRESS_CERT | base64 -d)" \
     aksIngressControllerKey="$(echo $INGRESS_KEY | base64 -d)"

```

```bash

# get the name of the deployment key vault
export ASB_KV_NAME=$(az deployment group show -g $ASB_RG_CORE -n cluster-${ASB_TEAM_NAME} --query properties.outputs.keyVaultName.value -o tsv)

# get cluster name
export ASB_AKS_NAME=$(az deployment group show -g $ASB_RG_CORE -n cluster-${ASB_TEAM_NAME} --query properties.outputs.aksClusterName.value -o tsv)

# Get the public IP of our App gateway
export ASB_AKS_PIP=$(az network public-ip show -g $ASB_RG_SPOKE --name pip-BU0001A0008-00 --query ipAddress -o tsv)

```

```bash

# Get the AKS Ingress Controller Managed Identity details.
export ASB_TRAEFIK_RESOURCE_ID=$(az deployment group show -g $ASB_RG_CORE -n cluster-${ASB_TEAM_NAME} --query properties.outputs.aksIngressControllerPodManagedIdentityResourceId.value -o tsv)
export ASB_TRAEFIK_CLIENT_ID=$(az deployment group show -g $ASB_RG_CORE -n cluster-${ASB_TEAM_NAME} --query properties.outputs.aksIngressControllerPodManagedIdentityClientId.value -o tsv)
export ASB_POD_MI_ID=$(az identity show -n podmi-ingress-controller -g $ASB_RG_CORE --query principalId -o tsv)

# config traefik
export ASB_INGRESS_CERT_NAME=appgw-ingress-internal-aks-ingress-tls
export ASB_INGRESS_KEY_NAME=appgw-ingress-internal-aks-ingress-key

# save env vars
./saveenv.sh -y

```

#### Setup GitOps

##### Setup Traefik

```bash

rm -f gitops/ingress/02-traefik-config.yaml
cat templates/traefik-config.yaml | envsubst > gitops/ingress/02-traefik-config.yaml
rm -f gitops/ngsa/ngsa-ingress.yaml
cat templates/ngsa-ingress.yaml | envsubst > gitops/ngsa/ngsa-ingress.yaml

```

##### Setup Flux

```bash

# update flux.yaml
rm -f flux.yaml
cat templates/flux.yaml | envsubst  > flux.yaml

# get AKS credentials
az aks get-credentials -g $ASB_RG_CORE -n $ASB_AKS_NAME

# rename context for simplicity
kubectl config rename-context $ASB_AKS_NAME $ASB_TEAM_NAME

```

### Push Updates

> The setup process creates 5 new files. GitOps will not work unless these files are merged into your branch.

```bash

# load the env vars created by setup
# you can reload the env vars at any time by sourcing the file
source ${ASB_TEAM_NAME}.asb.env

# check deltas - there should be 5 new files
git status

# push to your branch
git add .
git commit -m "added cluster config"
git push

```

### Validation

```bash

# get AKS credentials
az aks get-credentials -g $ASB_RG_CORE -n $ASB_AKS_NAME

# rename context for simplicity
kubectl config rename-context $ASB_RG_CORE $ASB_TEAM_NAME

# check the nodes
# requires Azure login
kubectl get nodes

# check the pods
kubectl get pods -A

### Congratulations!  Your AKS Secure Baseline cluster is running!

```

### Deploy Configuration and App (optional)

> ASB is designed to use Flux for GitOps

To manually deploy the entire stack for testing

```bash

kubectl apply -f gitops

```

### Setup Flux

> ASB uses `Flux CD` for `GitOps`

```bash

# setup flux
kubectl apply -f flux.yaml

# check the pods until everything is running
kubectl get pods -n flux-cd -l app.kubernetes.io/name=flux

# check flux logs
kubectl logs -n flux-cd -l app.kubernetes.io/name=flux

```

### Validate Ingress

> ASB uses `Traefik` for `ingress`

```bash

# wait for traefik pods to start
### this can take 2-3 minutes
kubectl get pods -n ingress

## Verify with curl
### this can take 1-2 minutes
### if you get a 502 error retry until you get 200

# test http redirect for a 302
curl -i http://${ASB_DOMAIN}/memory/healthz

# test https
curl https://${ASB_DOMAIN}/memory/version

### Congratulations! You have GitOps setup on ASB!

```

### Resetting the cluster

> Reset the cluster to a known state
>
> This is normally signifcantly faster for inner-loop development than recreating the cluster

```bash

# delete the namespaces
# this can take 4-5 minutes
### order matters as the deletes will hang and flux could try to re-deploy
kubectl delete ns flux-cd
kubectl delete ns ngsa
kubectl delete ns ingress
kubectl delete ns cluster-baseline-settings

# delete any additional namespaces you created

# check the pods
kubectl get pods -A

# start over at Setup Flux

```

### Running Multiple Clusters

- start a new shell to clear the ASB_* env vars
- start at `Set Team Name`
- make sure to use a new ASB_TEAM_NAME
- you must create a new branch or GitOps will fail on both clusters

### Delete Resources

> Do not just delete the resource groups

Make sure ASB_TEAM_NAME is set correctly

```bash

echo $ASB_TEAM_NAME

```

Delete the cluster

```bash

# resource group names
export ASB_RG_CORE=rg-${ASB_TEAM_NAME}-core
export ASB_RG_HUB=rg-${ASB_TEAM_NAME}-networking-hub
export ASB_RG_SPOKE=rg-${ASB_TEAM_NAME}-networking-spoke

export ASB_AKS_NAME=$(az deployment group show -g $ASB_RG_CORE -n cluster-${ASB_TEAM_NAME} --query properties.outputs.aksClusterName.value -o tsv)
export ASB_KEYVAULT_NAME=$(az deployment group show -g $ASB_RG_CORE -n cluster-${ASB_TEAM_NAME} --query properties.outputs.keyVaultName.value -o tsv)
export ASB_LA_HUB=$(az monitor log-analytics workspace list -g $ASB_RG_HUB --query [0].name -o tsv)

# delete and purge the key vault
az keyvault delete -n $ASB_KEYVAULT_NAME
az keyvault purge -n $ASB_KEYVAULT_NAME

# hard delete Log Analytics
az monitor log-analytics workspace delete -y --force true -g $ASB_RG_CORE -n la-${ASB_AKS_NAME}
az monitor log-analytics workspace delete -y --force true -g $ASB_RG_HUB -n $ASB_LA_HUB

# delete the resource groups
az group delete -y --no-wait -g $ASB_RG_CORE
az group delete -y --no-wait -g $ASB_RG_HUB
az group delete -y --no-wait -g $ASB_RG_SPOKE

# delete from .kube/config
kubectl config delete-context $ASB_TEAM_NAME

### delete your git branch if desired

# group deletion can take 10 minutes to complete
az group list -o table | grep $ASB_TEAM_NAME

### sometimes the spokes group has to be deleted twice
az group delete -y --no-wait -g $ASB_RG_SPOKE

```

## Challenges

### Challenge 1

- TODO - add https redirect here

Here are some ideas for `next steps`

- Create a dashboard visualizing blocked traffic
- Add ghcr.io as a container registry
- Deploy `LodeRunner` from `ghcr.io/retaildevcrews/loderunner:latest`
- Explore `Azure Log Analytics` for observability
- Explore an idea from your experiences / upcoming customer projects
- Fix a bug that you ran into during the hack
- Most importantly, `have fun and learn at the hack!`

### Random Notes

```bash

# stop your cluster
az aks stop --no-wait -n $ASB_AKS_NAME -g rg-bu0001a0008-$ASB_TEAM_NAME
az aks show -n $ASB_AKS_NAME -g rg-bu0001a0008-$ASB_TEAM_NAME --query provisioningState -o tsv

# start your cluster
az aks start --no-wait --name $ASB_AKS_NAME -g rg-bu0001a0008-$ASB_TEAM_NAME
az aks show -n $ASB_AKS_NAME -g rg-bu0001a0008-$ASB_TEAM_NAME --query provisioningState -o tsv

# disable policies (last resort for debugging)
az aks disable-addons --addons azure-policy -g rg-bu0001a0008-$ASB_TEAM_NAME -n $ASB_AKS_NAME

```
