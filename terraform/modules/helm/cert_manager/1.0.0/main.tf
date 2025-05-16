resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  create_namespace = true
  namespace        = var.namespace
  chart            = "cert-manager"
  repository       = "https://charts.jetstack.io"
  version          = var.chart_version

  values = [
    var.values
  ]

  set {
    name  = "crds.enabled"
    value = "true"
  }
}
