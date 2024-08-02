
data "doppler_secrets" "autotest_secrets" {
  project = var.ctx_doppler_project
  config  = var.ctx_doppler_config
}


module "autotest_cloudflare_tunnels" {

  source                = "../"
  cloudflare_account_id = data.doppler_secrets.autotest_secrets.map.CTX_CLOUDFLARE_ACCOUNT_ID
}
