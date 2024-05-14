resource "helm_release" "metrics-server" {
    count            = var.is_metrics_server_enabled ? 1 : 0
    name             = "metrics-server"
    repository       = "https://kubernetes-sigs.github.io/metrics-server/"
    chart            = "metrics-server"
    create_namespace = false
    namespace        = "kube-system"

    set {
      name = "replicas"
      value = 3
    }
}
