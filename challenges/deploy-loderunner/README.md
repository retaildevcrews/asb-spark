# Deploy Loderunner

## Background

To create a load test for our NGSA application, we need to run our end-to-end test tool (Loderunner) which generates https requests and sends them to our NGSA application. More about Loderunner can be found [here](#loderunner). 

The Loderunner application needs to be deployed on our AKS cluster. Create a Kubernetes manifest file (yaml) to define and create the appropriate resource(s) needed to deploy Loderunner. The inputs needed to deploy Loderunner on our AKS cluster are shown below. Using these inputs, Loderunner will generate approximately 1 request per second when deployed. 

```yaml

container:
    ghcr.io/retaildevcrews/ngsa-lr:beta
name:
    l8r-load-1
namespace:
    ngsa
args:
    -l  "1000", -r, -s https://< your subdomain name >.aks-sb.com, -f memory-benchmark.json

```

###Prerequisite

This challenge depends on [Pulling from GitHub Container Registry](../github-container-registry/README.md) to enable the cluster to pull container images from `ghcr.io` 

### Validate

After have applied your yaml file you can check your loderunner pod logs validate that HTTP requests are being sent.

### Bonus

Modify the input arguments to have Loderunner (lr8) generate approximately 50 req/sec.

## Resources
- [K8 Objects](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/)
- [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Static-pod](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)
- [K8 Cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#creating-objects)

## Hints


### Loderunner

#### Running Loderunner from command line

```bash
# pull image from GitHub Container Repository 
docker pull ghcr.io/retaildevcrews/ngsa-lr:beta

# run loderunner with --help option; this should output command line options shown below
docker run ghcr.io/retaildevcrews/ngsa-lr:beta --help
```
![Loderunner Parameters](./images/../image/LodeRunnerParameters.PNG)

#### Sample Interactive Loderunner Command

```bash
# after running this command, you should see json output at the command line describing HTTP requests
docker run ghcr.io/retaildevcrews/ngsa-lr:beta -l "1000" -r -s https://worka.aks-sb.com -f memory-benchmark.json
```
