# Change Log

## May 2021

- Intial Release
  - cloned mspnp/azure-secure-baseline
  - created `ocw.md` as a single-file walkthrough for the hack
  - automated setup with `setup.sh`
  - added `.devcontainer` for `Codespaces` support
  - added team GitHub templates in `.github/*`
  - added NGSA-Memory deployment yaml in `deploy/*`
  - added `engineering docs` in `docs/*`
  - added MS Open Source standard content
  - added ability to use self-signed certs with random domain names
  - configured flux to use `rdc/gitops` repo and use `flux-cd` namespace
  - removed `contoso-com` from component names
  - code review
  - security review

- Changed Files
  - 02-ca-certificates.md
  - 04-networking.md
  - 07-workload-prerequisites.md
  - 08-secret-managment-and-ingress-controller.md
  - README.md
  - cluster-stamp.json
  - cluster-manifests/cluster-baseline-settings/flux.yaml
  - inner-loop-scripts/azcli/cluster-deploy.azcli
  - inner-loop-scripts/shell/1-cluster-stamp.sh
  - workload/traefik.yaml

- Added Files
  - .devcontainer/*
  - .github/*
  - deploy/*
  - docs/*
  - CHANGELOG.md
  - CODE_OF_CONDUCT.md
  - SECURITY.md
  - SUPPORT.md
  - ocw.md
  - setup.sh
