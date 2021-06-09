# Setup service principal to manage DNS records for hack participants

This documentation walks through the steps needed to configure DNS updates through GitHub actions.

## Initial Setup

The initial setup script will create a service principal and give it access to the DNS Zone for the hack. The runner of this initial setup script needs access to the subscription, permissions to create service principals, and permissions to update roles for service principals. This is meant to run when first setting up the GitHub Action.

```bash

# Run the script to create the service principal
./create-dns-sp.sh

# The script will output the credential data for the service principal
# Copy this into a GitHub secret for later use by the GitHub Action.

# TODO: add name of github secret

```

## GitHub Action

The GitHub Action can now use the service principal to update the required DNS Zone on behalf of the hack participants.

TODO:

- add link to github action workflow file
- use <https://github.com/marketplace/actions/azure-cli-action>

```bash

# a GitHub Action is already configured to run this script when a hack participant pushes their branch changes to GitHub.
./create-dns-record.sh

```
