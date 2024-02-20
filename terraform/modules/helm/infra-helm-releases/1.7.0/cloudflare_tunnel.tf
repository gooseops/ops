resource "helm_release" "cloudflare_tunnel" {
    count            = var.is_cloudflare_tunnel_enabled ? 1 : 0
    name             = "${var.cloudflare_tunnels.name}-${var.k8s_cluster_version}"
    chart            = "${var.deltacm_home}/kubernetes/helmcharts/cloudflare-tunnel/"
    create_namespace = true
    namespace        = var.namespace

    set {
        name  = "fullnameOverride"
        value = "cloudflare-tunnel"
    }
    set {
        name  = "accounttag"
        value = var.cloudflare_tunnels.account_id
    }
    set {
        name  = "tunnelid"
        value = var.cloudflare_tunnels.id
    }
    set {
        name  = "tunnelname"
        value = var.cloudflare_tunnels.name
    }
    set {
        name  = "tunnelsecret"
        value = var.cloudflare_tunnels.secret
    }
    set {
        name  = "webzone"
        value = "{${join(",", var.domains)}}"
    }
    set {
        name  = "catchall_service"
        value = "http://traefik-${var.namespace}.${var.namespace}"
    }

    values = [
        "${fileexists("${var.deltacm_home}/kubernetes/values/cloudflare-tunnel-chart.values.yaml") ? file("${var.deltacm_home}/kubernetes/values/cloudflare-tunnel-chart.values.yaml") : file("/dev/null")}",
        "${fileexists("${var.deltacm_home}/kubernetes/values/cloudflare-tunnel-chart.${var.namespace}.values.yaml") ? file("${var.deltacm_home}/kubernetes/values/cloudflare-tunnel-chart.${var.namespace}.values.yaml") : file("/dev/null")}"
    ]
}
