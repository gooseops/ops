
resource "cloudflare_dns_record" "dns_record" {
  name    = var.name
  type    = var.type
  zone_id = var.zone_id
  content = var.value
  proxied = var.proxied
  ttl     = var.ttl
}
