module "vw_cert" {
  source = "../../../modules/tls/self_signed_cert/1.0.0"

  prvkey       = data.doppler_secrets.prod_secrets.map.VW_TLS_PRVKEY
  common_name  = "vw.gooseops.local"
  organization = "GooseOps, LLC"
  hostnames    = ["vw.gooseops.local", "*.vw.gooseops.local"]
  ip_addresses = [module.vaultwarden.vm_ip]
  depends_on   = [module.vaultwarden]
}
