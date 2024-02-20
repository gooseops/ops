resource "helm_release" "cloudflare_tunnel" {
    name             = "${var.cloudflare_tunnel.name}"
    chart            = "${path.module}/../../../../../helm/charts/cloudflare-tunnel/"
    create_namespace = true
    namespace        = var.namespace

    set {
        name  = "fullnameOverride"
        value = "cloudflare-tunnel"
    }
    set_sensitive {
        name  = "accounttag"
        value = var.cloudflare_tunnel.account_id
    }
    set_sensitive {
        name  = "tunnelid"
        value = var.cloudflare_tunnel.id
    }
    set_sensitive {
        name  = "tunnelname"
        value = var.cloudflare_tunnel.name
    }
    set_sensitive {
        name  = "tunnelsecret"
        value = var.cloudflare_tunnel.secret
    }
    set {
        name  = "webzone"
        value = "{${join(",", var.domains)}}"
    }
    set {
        name  = "catchall_service"
        value = "http://traefik.${var.namespace}"
    }

}
