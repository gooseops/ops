resource "random_id" "cloudflare_prefix" {
  byte_length = 3
  prefix      = "CF-"
}
#
# Cloudflare Tunnel configuration
#
resource "random_id" "tunnel_secret" {
  byte_length = 35
}

locals {
  dns_safe_prefix = lower("${replace(random_id.cloudflare_prefix.hex, "_", "-")}")
}

resource "cloudflare_tunnel" "tunnel" {
  account_id = var.cloudflare_account_id
  name       = "${local.dns_safe_prefix}-${var.tunnel_name}"
  secret     = random_id.tunnel_secret.b64_std
}
