# AKS Secure Baseline Hack (internal)

## Welcome to the Patterns and Practices (PnP) AKS Secure Baseline (ASB) hack!

- This repo contains modifications and additions to tailor it specifically for hack events and **should not be used for production deployments**
  - Original PnP AKS Secure Baseline repo is located [here](https://github.com/mspnp/aks-secure-baseline)
  - Please refer to the PnP repo as the `upstream repo`

> These steps are for setting up AKS secure baseline on internal Microsoft AIRS subscriptions
> Use the steps in [readme.md](./README.md) if you're not using an AIRS subscription

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

- The `AKS Secure Baseline` repo for the hack is at [github/retaildevcrews/ocw-asb](https://github.com/retaildevcrews/ocw-asb)
- Open this repo in your web browser
- Create a new `Codespace` in this repo
  - **Do not choose fork**
  - If the `fork option` appears, you need to request contributor permission to the repo

```bash

# login to your Azure subscription
az login

# verify the correct subscription
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
 
if [[ $ASB_TEAM_NAME =~ (^[a-z])([a-z0-9]{1,10})$ ]]; then 
  # make sure the resource group doesn't exist
  az group list -o table | grep $ASB_TEAM_NAME

  # make sure the branch doesn't exist
  git branch -a | grep $ASB_TEAM_NAME

  # if either exists, choose a different team name and try again
else 
    echo "Team name doesn't match required format: [starts with a-z, [a-z,0-9], max length 8]" 
fi

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

./airs-setup.sh $ASB_TEAM_NAME

```

### Push Updates

> start at the Push Updates section in `readme.md`

### Delete Resources

### This is different than `readme.md`

> Do not just delete the resource groups

```bash

./airs-cleanup.sh $ASB_TEAM_NAME

### delete your git branch if desired

# group deletion can take 10 minutes to complete
az group list -o table | grep $ASB_TEAM_NAME

### sometimes the spokes group has to be deleted twice
az group delete -y --no-wait -g $ASB_RG_SPOKE

```
