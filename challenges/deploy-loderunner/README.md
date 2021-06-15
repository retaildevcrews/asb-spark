# Deploy LodeRunner

## Background

To create a load test for our NGSA application, we need to run our end-to-end test tool (LodeRunner) which generates https requests and sends them to our NGSA application. More about LodeRunner can be found [here](#loderunner).

The LodeRunner application needs to be deployed on our AKS cluster. Create a Kubernetes manifest file (yaml) to define and create the appropriate resource(s) needed to deploy LodeRunner. The inputs needed to deploy LodeRunner on our AKS cluster are shown below. Using these inputs, LodeRunner will generate approximately 1 request per second when deployed.

```yaml

container:
    ghcr.io/retaildevcrews/ngsa-lr:beta
namespace:
    ngsa
args:
    --sleep 1000 --run-loop --server https://< your subdomain name >.aks-sb.com --files memory-benchmark.json

```

### Prerequisite

This challenge depends on [Pulling from GitHub Container Registry](../github-container-registry/README.md) to enable the cluster to pull container images from `ghcr.io`

### Validate

After have applied your yaml file you can check your LodeRunner pod logs validate that HTTP requests are being sent.

### Bonus

Modify the input arguments to have LodeRunner generate approximately 50 req/sec.

## Resources

- [K8 Objects](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/)
- [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Static-pod](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)
- [K8 Cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#creating-objects)

## Hints

### Running LodeRunner from command line

```bash
# pull image from GitHub Container Repository 
docker pull ghcr.io/retaildevcrews/ngsa-lr:beta

# run LodeRunner with --help option; this should output command line options shown below
docker run ghcr.io/retaildevcrews/ngsa-lr:beta --help
```

### Sample Interactive LodeRunner Command

```bash
# after running this command, you should see json output at the command line describing HTTP requests
docker run ghcr.io/retaildevcrews/ngsa-lr:beta --sleep 1000 --run-loop --server $ASB_DOMAIN --files memory-benchmark.json
```
