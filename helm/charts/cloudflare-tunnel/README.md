# Information
Docs for `cloudflare-tunnel` helm-chart in `deltacm/kubernetes/helmcharts/`.  This is a helm-chart maintained by Platform Engineering Team 3 and used for deploying the cloudflare tunnel to Kubernetes.  

This chart is currently hardcoded to fit Delta Defense's kubernetes infrastructure and networking environment and may not work with other specific use cases.

## Table of Contents

[[_TOC_]]

## Installation
```
helm install <release-name> ${DELTACM_HOME}/kubernetes/helmcharts/cloudflare-tunnel/ -f <values-file>
```
- If there are more than one values.yaml file, then make sure to add multiple `-f` flags with the path to each. (i.e. `-f values-file1.yaml -f values-file2.yaml`)
- Installation of this chart onto a cluster is usually achieved using terraform and a manual installation is rarely necessary unless testing features.

## Values
- See this chart's [values.yaml](https://gitlab.com/delta-defense/platform-engineering/automation/deltacm/-/blob/main/kubernetes/helmcharts/cloudflare-tunnel/values.yaml) file for configuration options and explanations.

## Templates
- The cloudflare-tunnel helm chart deploys a daemonset, a configmap, and secret based on the instructions from these [cloudflare docs](https://developers.cloudflare.com/cloudflare-one/tutorials/many-cfd-one-tunnel/) and this [manifest file](https://github.com/cloudflare/argo-tunnel-examples/blob/master/named-tunnel-k8s/cloudflared.yaml).

## Development
- Currently development for the `cloudflare-tunnel` helm-chart is maintained in `deltacm`.
- Any changes to the `cloudflare-tunnel` helm-chart require an increment in the helm chart version in the [Charts.yaml](https://gitlab.com/delta-defense/platform-engineering/automation/deltacm/-/blob/main/kubernetes/helmcharts/cloudflare-tunnel/Chart.yaml) file.
- Any changes significantly affecting how this helm-chart works, should be documented in this wiki.
