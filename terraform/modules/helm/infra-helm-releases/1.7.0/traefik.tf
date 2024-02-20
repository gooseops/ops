resource "helm_release" "traefik" {
    count            = var.is_traefik_enabled ? 1 : 0
    name             = "${var.ctx_doppler_config_dns_safe}-traefik-${var.k8s_cluster_version}"
    repository       = "https://traefik.github.io/charts"
    chart            = "traefik"
    create_namespace = true
    namespace        = var.namespace

    set {
        name  = "fullnameOverride"
        value = "traefik-${var.namespace}"
    }


    values = [
        "${fileexists("${var.deltacm_home}/kubernetes/values/traefik-chart.values.yaml") ? file("${var.deltacm_home}/kubernetes/values/traefik-chart.values.yaml") : file("/dev/null")}",
        "${fileexists("${var.deltacm_home}/kubernetes/values/traefik-chart.${var.namespace}.values.yaml") ? file("${var.deltacm_home}/kubernetes/values/traefik-chart.${var.namespace}.values.yaml") : file("/dev/null")}"
    ]
}