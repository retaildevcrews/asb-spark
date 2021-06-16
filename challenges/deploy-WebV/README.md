# Deploy WebValidate

## Background

Web Validate (WebV) is our end-to-end test tool that generates web requests and sends them to our NGSA application. These web requests can be used to enable load tests and to verify that the NGSA application is handling web requests correctly. More information about running WebV interactively from the command line can be found [here](https://github.com/microsoft/webvalidate).

The WebV application needs to be deployed on our AKS cluster. Create a Kubernetes manifest file (yaml) to define and create the appropriate resource(s) needed to deploy WebV. The inputs needed to deploy WebV on our AKS cluster are shown below. Using these inputs, WebV will generate approximately 1 request per second when deployed.

```yaml

namespace:
    ngsa
args:
    --sleep 1000 --run-loop --server https://${ASB_TEAM_NAME}.aks-sb.com --files memory-benchmark.json

```

### Prerequisite

This challenge depends on [Deploying from Azure Container Registry](../azure-container-registry/README.md)

### Validate

After you have deployed the Web Validate tool, you can check WebV pod logs to validate that web requests are being sent and the correct status codes are being returned.

### Bonus Challenge 1

Modify the input arguments to have WebV generate approximately 50 req/sec.

### Bonus Challenge 2

Explore the different ways you could scale WebV to generate more than 1000 req/sec.

#### Hint

There are three possible ways.

## Resources

- [Kubernetes Objects](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/)
- [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Kubernetes Cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#creating-objects)

## Hints

### Running WebV from command line

```bash

# pull image from GitHub Container Repository 
docker pull ghcr.io/retaildevcrews/webvalidate:beta

# run WebV with --help option; this should output command line options shown below
docker run ghcr.io/retaildevcrews/webvalidate:beta --help

```

### Sample Interactive WebV Command

```bash

# after running this command, you should see json output at the command line describing web requests

# the WebV command below sends web requests to the server $ASB_DOMAIN in a continuous loop at the rate of one request per second

# command line arguments:
#   --sleep 1000: 1000ms between web requests (one request per second)
#   --run-loop: run in a continuous loop
#   --server $ASB_DOMAIN: test the server $ASB_DOMAIN
#   --files memory-benchmark.json: test file(s) containing web requests and expected response

# to terminate this test after a set amount of time you can set the --duration argument (time in seconds). Otherwise, use CTRL-C to stop it.

docker run -it --rm ghcr.io/retaildevcrews/webvalidate:beta --sleep 1000 --run-loop --verbose --duration 30 --log-format Json --server "https://${ASB_DOMAIN}" --files memory-benchmark.json

```
