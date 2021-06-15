# Deploy WebV

## Background

WebV is our end-to-end test tool that generates https requests and sends them to our NGSA application. These https requests can be used to enable load tests and to verify that the NGSA application is handling https requests correctly. More information about running WebV interactively from the command line can be found [here](https://github.com/retaildevcrews/webvalidate/blob/main/README.md).

The WebV application needs to be deployed on our AKS cluster. Create a Kubernetes manifest file (yaml) to define and create the appropriate resource(s) needed to deploy WebV. The inputs needed to deploy WebV on our AKS cluster are shown below. Using these inputs, WebV will generate approximately 1 request per second when deployed.

```yaml

container:
    ghcr.io/retaildevcrews/ngsa-webv:beta
namespace:
    ngsa
args:
    --sleep 1000 --run-loop --server https://< your subdomain name >.aks-sb.com --files memory-benchmark.json

```

### Prerequisite

This challenge depends on [Pulling from GitHub Container Registry](../github-container-registry/README.md) to enable the cluster to pull container images from `ghcr.io`

### Validate

After you have applied your yaml file you can check your WebV pod logs to validate that HTTP requests are being sent.

### Bonus

Modify the input arguments to have WebV generate approximately 50 req/sec.

## Resources

- [Kubernetes Objects](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/)
- [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Static-pod](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)
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

# after running this command, you should see json output at the command line describing HTTP requests

# the WebV command below sends HTTP requests to the server $ASB_DOMAIN in a continuous loop at the rate of one request per second

# command line arguments:
#   --sleep 1000: 1000ms between HTTP requests (one request per second)
#   --run-loop: run in a continuous loop
#   --server $ASB_DOMAIN: test the server $ASB_DOMAIN
#   --files memory-benchmark.json: test file(s) containing HTTP requests and expected response

# to terminate this test after a set amount of time you can set the --duration argument (time in seconds). Otherwise, use CTRL-C to stop it.

docker run ghcr.io/retaildevcrews/webvalidate:beta --sleep 1000 --run-loop --server $ASB_DOMAIN --files memory-benchmark.json
```
