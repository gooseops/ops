module "cf_tunnel_helm_release" {
    source = "../../../modules/helm/cloudflare_tunnel/1.0.0"

    namespace = "default"
    cloudflare_tunnel = module.kubernetes_cf_tunnel.tunnel_map
}