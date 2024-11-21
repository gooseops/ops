data "doppler_secrets" "prod_secrets" {
  project = "ops"
  config  = "prod"
}

data "cloudflare_zone" "gooseops" {
  name = "gooseops.com"
}
