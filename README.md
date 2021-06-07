# AKS Secure Baseline Hack

> Welcome to the Patterns and Practices (PnP) AKS Secure Baseline (ASB) hack!

- The Patterns and Practices AKS Secure Baseline repo is located [here](https://github.com/mspnp/aks-secure-baseline)
  - This repo is a summarization specifically for the hack and `should not be used for production deployments`
  - Please refer to the PnP repo as the `upstream repo`

## Filing Bugs

> Please capture any bugs, issues or ideas on the `GitHub Board`

## Deploying ASB

### Getting Started

### Login to Azure Portal

- Login using the credentials provided at <https://portal.azure.com>
  - You will need to change your password

### Create Codespace

- The `AKS Secure Baseline` repo for the hack is at [github/retaildevcrews/ocw-asb](https://github.com/retaildevcrews/ocw-asb)
- Open this repo in your web browser
- Create a new `Codespace` in this repo
  - If the `fork option` appears, you need to request permission to the repo
  - Do not choose fork
- If you are not using Codespaces, ask your coach for this value
  - `export ASB_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

```bash


# login to the Azure subscription for the hack
az login -t $ASB_TENANT_ID

# verify the correct subscription - bartr-cloudatx-asb
az account show

# install kubectl and kubelogin
sudo az aks install-cli

```

### Set Team Name

> Team Name is very particular and won't fail for about an hour ...

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

> This takes 45 - 60 minutes to complete

```bash

./setup.sh $ASB_TEAM_NAME

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

### Add Team to Cluster Admin Group

```bash

### repeat for each of the other members of your team
az ad group member add -g $ASB_CLUSTER_ADMIN_GROUP --member-id $(az ad user show --query objectId -o tsv --id \
changeThisForEachTeamMember@${ASB_TENANT_TLD})

# list users
az ad group member list -g $ASB_CLUSTER_ADMIN_GROUP  --query [].mailNickname -o table

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

```bash

./cleanup.sh $ASB_TEAM_NAME

### delete your git branch if desired

# group deletion can take 10 minutes to complete
az group list -o table | grep $ASB_TEAM_NAME

### sometimes the spokes group has to be deleted twice
az group delete -y --no-wait -g $ASB_RG_SPOKE

```

## Challenges

Here are some ideas for `next steps`

> Please document and PR the steps (even if incomplete) into the /challenges folder

- Integrate `APIM` into the architecture
- Install all the pre-reqs locally and create a cluster from your laptop
  - make sure to use a unique `ASB_TEAM_NAME`
- Use the existing `Key Vault` to load the certs
  - Copy and modify the template to not create a new Key Vault
- Create a dashboard visualizing blocked traffic
- Explore `Azure Log Analytics` for observability
- Deploy `Prometheus` and `Grafana` for CNCF observability
- Deploy `Fluent Bit` to `Log Analytics` for `Application Logging`
  - Instructions [here](https://aka.ms/fbla)
- Run `Load Tests` and test `auto-scaling`
- Do a `blue / green` deployment of `NGSA-Memory`
- Deploy two `ASB Clusters` in the same `Network Hub`
- Deploy two `ASB Clusters` in `different regions`
- Deploy `Cosmos DB` in the network and add `NGSA-Cosmos` to the cluster
- Explore an idea from your experiences / upcoming customer projects
- Experiment with `AutoGitOps`
- Fix a `bug` that you ran into during the `hack`
- Fix a `bug` from the board
- Improve the `Developer Experience` (several ideas on the board or come up with your own!)
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
