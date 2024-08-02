# Information
Docs for `cloudflare-tunnel` helm-chart in `ops/helm/charts/`.  This is a helm-chart maintained by GooseOps and used for deploying the cloudflare tunnel to Kubernetes.  

## Table of Contents

[[_TOC_]]

## Installation
```
helm install <release-name> ops/helm/charts/cloudflare-tunnel/ -f <values-file>
```
- If there are more than one values.yaml file, then make sure to add multiple `-f` flags with the path to each. (i.e. `-f values-file1.yaml -f values-file2.yaml`)
- Installation of this chart onto a cluster is usually achieved using terraform and a manual installation is rarely necessary unless testing features.

## Values
- See this chart's `values.yaml` file for configuration options and explanations.

## Templates
- The cloudflare-tunnel helm chart deploys a daemonset, a configmap, and secret based on the instructions from these [cloudflare docs](https://developers.cloudflare.com/cloudflare-one/tutorials/many-cfd-one-tunnel/) and this [manifest file](https://github.com/cloudflare/argo-tunnel-examples/blob/master/named-tunnel-k8s/cloudflared.yaml).
