
data "doppler_secrets" "autotest_secrets" {
    project = var.ctx_doppler_project
    config  = var.ctx_doppler_config
}


module "autotest_cloudflare_tunnels" {

    source = "../"
    ctx_cloudflare_account_id   = data.doppler_secrets.autotest_secrets.map.CTX_CLOUDFLARE_ACCOUNT_ID
    ctx_doppler_config          = data.doppler_secrets.autotest_secrets.map.DOPPLER_CONFIG
    ctx_doppler_config_dns_safe = data.doppler_secrets.autotest_secrets.map.CTX_DOPPLER_CONFIG_DNS_SAFE
    ctx_doppler_project         = data.doppler_secrets.autotest_secrets.map.DOPPLER_PROJECT
}
