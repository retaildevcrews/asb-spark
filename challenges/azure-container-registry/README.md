# Pulling from GitHub Container Registry

## Background

Enable the cluster to pull container images from `ghcr.io`

- Deloy `ngsa-ghcr.yaml` from this directory
  - The pod will fail to start due to `ErrImgPull`
- Delete the deployment

## Remediation

- Update the Azure image source policy
- Update the application firewall rule

## Hints

> Docker pull gets redirected from ghcr.io

- Add the following FQDNs in addition to ghcr.io
  - *.ghcr.io
  - *.githubusercontent.com
