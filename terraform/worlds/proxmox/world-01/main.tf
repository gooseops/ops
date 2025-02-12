data "doppler_secrets" "prod_secrets" {
  project = "ops"
  config  = "prod"
}

data "cloudflare_zone" "gooseops" {
  zone_id = data.doppler_secrets.prod_secrets.map.CLOUDFLARE_GOOSEOPS_COM_ZONE_ID
}
