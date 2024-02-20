locals {
  values= <<EOT
commonLabels: 
  datadog-apm: "true"
datadog:
  site:  datadoghq.com
  leaderElection: true
  collectEvents: true
  rbac.create: true
  containerExclude: "kube_namespace:.*"
  containerInclude: "kube_namespace:prod kube_namespace:staging"
  log_level: WARN
  logs:
    enabled: true
  apm:
    portEnabled: true
  processAgent:
    enabled: true
    processCollection: true
  # helmCheck:
  #   enabled: true
  #   collectEvents: true
clusterAgent:
  enabled: true
  replicas: 2
  createPodDisruptionBudget: true
  additionalLabels:
    datadog-apm: "true"
agents:
  enabled: true
  additionalLabels:
    datadog-apm: "true"
  ## Eventually we will use 'metricsProvider' for autoscaling but currently
  ## we don't have an appropriate app key for testing or a use case.
  ## Kubernetes Phase 2.
  # metricsProvider:
  #   enabled: false
    # useDatadogMetrics: true
EOT
}
resource "helm_release" "datadog" {
    count            = var.is_datadog_enabled ? 1 : 0
    name             = "datadog-${var.k8s_cluster_version}"
    repository       = "https://helm.datadoghq.com"
    chart            = "datadog"
    create_namespace = true
    namespace        = "datadog"

    set_sensitive {
        name  = "datadog.apiKey"
        value = var.datadog_api_key
    }
    set_sensitive {
        name  = "datadog.appKey"
        value = var.datadog_app_key
    }
    set {
        name  = "datadog.clusterName"
        value = var.cluster_name
    }
        set {
        name  = "datadog.logs.containerCollectAll"
        value = var.datadog_log_collection
    }

    values = [
        local.values,
        "${fileexists("${var.deltacm_home}/kubernetes/values/datadog-delta.values.yaml") ? file("${var.deltacm_home}/kubernetes/values/datadog-delta.values.yaml") : file("/dev/null")}",
        # "${fileexists("${var.deltacm_home}/kubernetes/values/datadog-delta.${var.namespace}.values.yaml") ? file("${var.deltacm_home}/kubernetes/values/datadog-delta.${var.namespace}.values.yaml") : file("/dev/null")}"
    ]
}
