# Pulling from GitHub Container Registry

## Background

Enable the cluster to pull container images from `ghcr.io`

## Steps

- Update the Azure image source policy
- Update the image application firewall rule

## Hints

> Docker pull gets redirected from ghcr.io

- Add the following FQDNs in addition to ghcr.io
  - *.ghcr.io
  - *.githubusercontent.com
