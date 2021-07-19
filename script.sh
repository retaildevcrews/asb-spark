
# get AAD cluster admin group
export ASB_CLUSTER_ADMIN_ID=$(az ad group show -g $ASB_CLUSTER_ADMIN_GROUP --query objectId -o tsv)

# verify AAD admin group
echo $ASB_CLUSTER_ADMIN_GROUP
echo $ASB_CLUSTER_ADMIN_ID


# set GitOps repo
# (earlier) export ASB_GIT_REPO=$(git remote -v | cut -f 2 | cut -f 1 -d " " | head -n 1)
export ASB_GIT_REPO=$(git remote get-url origin)
export ASB_GIT_BRANCH=$ASB_TEAM_NAME
export ASB_GIT_PATH=gitops

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


# create the resource groups
az group create -n $ASB_RG_HUB -l $ASB_LOCATION
az group create -n $ASB_RG_SPOKE -l $ASB_LOCATION
az group create -n $ASB_RG_CORE -l $ASB_LOCATION


# this section takes 15-20 minutes to complete

# create hub network
az deployment group create -g $ASB_RG_HUB -f networking/hub-default.json -p location=${ASB_LOCATION} --query name
export ASB_VNET_HUB_ID=$(az deployment group show -g $ASB_RG_HUB -n hub-default --query properties.outputs.hubVnetId.value -o tsv)

# create spoke network
az deployment group create -g $ASB_RG_SPOKE -f networking/spoke-BU0001A0008.json -p location=${ASB_LOCATION} hubVnetResourceId="${ASB_VNET_HUB_ID}" --query name
export ASB_NODEPOOLS_SUBNET_ID=$(az deployment group show -g $ASB_RG_SPOKE -n spoke-BU0001A0008 --query properties.outputs.nodepoolSubnetResourceIds.value -o tsv)

# create Region A hub network
az deployment group create -g $ASB_RG_HUB -f networking/hub-regionA.json -p location=${ASB_LOCATION} nodepoolSubnetResourceIds="['${ASB_NODEPOOLS_SUBNET_ID}']" --query name
export ASB_SPOKE_VNET_ID=$(az deployment group show -g $ASB_RG_SPOKE -n spoke-BU0001A0008 --query properties.outputs.clusterVnetResourceId.value -o tsv)

./saveenv.sh -y


### this section takes 15-20 minutes

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
     aksIngressControllerKey="$(echo $INGRESS_KEY | base64 -d)" \
     --query name


# get the name of the deployment key vault
export ASB_KV_NAME=$(az deployment group show -g $ASB_RG_CORE -n cluster-${ASB_TEAM_NAME} --query properties.outputs.keyVaultName.value -o tsv)

# get cluster name
export ASB_AKS_NAME=$(az deployment group show -g $ASB_RG_CORE -n cluster-${ASB_TEAM_NAME} --query properties.outputs.aksClusterName.value -o tsv)

# Get the public IP of our App gateway
export ASB_AKS_PIP=$(az network public-ip show -g $ASB_RG_SPOKE --name pip-BU0001A0008-00 --query ipAddress -o tsv)

# Get the AKS Ingress Controller Managed Identity details.
export ASB_TRAEFIK_RESOURCE_ID=$(az deployment group show -g $ASB_RG_CORE -n cluster-${ASB_TEAM_NAME} --query properties.outputs.aksIngressControllerPodManagedIdentityResourceId.value -o tsv)
export ASB_TRAEFIK_CLIENT_ID=$(az deployment group show -g $ASB_RG_CORE -n cluster-${ASB_TEAM_NAME} --query properties.outputs.aksIngressControllerPodManagedIdentityClientId.value -o tsv)
export ASB_POD_MI_ID=$(az identity show -n podmi-ingress-controller -g $ASB_RG_CORE --query principalId -o tsv)

# config traefik
export ASB_INGRESS_CERT_NAME=appgw-ingress-internal-aks-ingress-tls
export ASB_INGRESS_KEY_NAME=appgw-ingress-internal-aks-ingress-key

./saveenv.sh -y


# traefik config
rm -f gitops/ingress/02-traefik-config.yaml
cat templates/traefik-config.yaml | envsubst > gitops/ingress/02-traefik-config.yaml

# app ingress
rm -f gitops/ngsa/ngsa-ingress.yaml
cat templates/ngsa-ingress.yaml | envsubst > gitops/ngsa/ngsa-ingress.yaml

# GitOps (flux)
rm -f flux.yaml
cat templates/flux.yaml | envsubst  > flux.yaml




# check deltas - there should be 4 new files
git status

# push to your branch
git add .
git commit -m "added cluster config"
git push


# get AKS credentials
az aks get-credentials -g $ASB_RG_CORE -n $ASB_AKS_NAME

# rename context for simplicity
kubectl config rename-context $ASB_AKS_NAME $ASB_TEAM_NAME

# check the nodes
# requires Azure login
kubectl get nodes

# check the pods
kubectl get pods -A

### Congratulations!  Your AKS Secure Baseline cluster is running!




# setup flux
kubectl apply -f flux.yaml

# ?? check the pods until everything is running
kubectl get pods -n flux-cd -l app.kubernetes.io/name=flux

# check flux logs
kubectl logs -n flux-cd -l app.kubernetes.io/name=flux


# wait for traefik pods to start
### this can take 2-3 minutes
kubectl get pods -n ingress

## Verify with curl
### this can take 1-2 minutes
### if you get a 502 error retry until you get 200

# test https
curl https://${ASB_DOMAIN}/memory/version

### Congratulations! You have GitOps setup on ASB!


