# Deploy Loderunner

## Background

We need to create load test for our NGSA application, in order to do that we will need to run our end-to-end test tool Loderunner.

Create a Kubernetes manifest file (yaml) to define and create the appropriate resource(s) with the following data, which will  generate approximately 1 req/sec.

    container:
        ghcr.io/retaildevcrews/ngsa-lr:beta
    name:
        l8r-load-1
    namespace:
        ngsa
    args:
        -l  "1000", -r, -s https://<your subdomain name>.aks-sb.com, -f memory-benchmark.json , --prometheus

### Bonus
Modified arguments to have Loderunner (lr8) generate approximately 50 req/sec.

## Resources
- TODO: Add more information about K8 commands ?? 
- [Do we need WebV ??????????????](https://github.com/microsoft/webvalidate)
- [K8 Objects](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/)
- [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Static-pod](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)
- [K8 Cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#creating-objects)

## Hints

#### Loderunner Parameters
![Loderunner Parameters](./images/../image/LodeRunnerParameters.PNG)
