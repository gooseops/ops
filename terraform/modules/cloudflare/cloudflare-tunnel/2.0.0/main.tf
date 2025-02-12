
resource "random_id" "tunnel_secret" {
  byte_length = 35
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id    = var.cloudflare_account_id
  name          = var.tunnel_name
  config_src    = var.config_src
  tunnel_secret = random_id.tunnel_secret.b64_std
}
