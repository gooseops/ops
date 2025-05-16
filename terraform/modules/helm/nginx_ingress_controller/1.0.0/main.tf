resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  create_namespace = true
  namespace        = var.namespace
  chart            = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx/"
  version          = var.chart_version

  values = [
    var.values
  ]

  set {
    name  = "controller.service.type"
    value = var.service_type
  }
}
