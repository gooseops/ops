resource "helm_release" "traefik" {
  count            = var.is_traefik_enabled ? 1 : 0
  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  create_namespace = true
  namespace        = var.namespace

  set {
    name  = "fullnameOverride"
    value = "traefik-${var.namespace}"
  }
}
