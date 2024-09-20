module "vw_cert_pem" {
  source = "../../../modules/doppler/secret/1.0.0"

  doppler_project = data.doppler_secrets.prod_secrets.project
  doppler_config  = data.doppler_secrets.prod_secrets.config
  secret_name     = "VW_TLS_CERT"
  secret_value    = module.vw_cert.cert_pem

  depends_on = [module.vw_cert]
}

module "vw_ip" {
  source = "../../../modules/doppler/secret/1.0.0"

  doppler_project = data.doppler_secrets.prod_secrets.project
  doppler_config  = data.doppler_secrets.prod_secrets.config
  secret_name     = "VW_IP"
  secret_value    = module.vaultwarden.vm_ip

  depends_on = [module.vaultwarden]
}
