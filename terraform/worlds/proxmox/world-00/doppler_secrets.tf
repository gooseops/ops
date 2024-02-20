module "tunnel_cname" {
    source = "../../../modules/doppler/secret/1.0.0"

    doppler_project = data.doppler_secrets.prod_secrets.map.DOPPLER_PROJECT
    doppler_config = data.doppler_secrets.prod_secrets.map.DOPPLER_CONFIG
    secret_name = upper("${replace(module.kubernetes_cf_tunnel.tunnel_map.name, "-", "_")}")
    secret_value = module.kubernetes_cf_tunnel.tunnel_map.cname
}
