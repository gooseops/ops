
resource "cloudflare_dns_record" "record" {
  name    = var.name
  type    = var.type
  zone_id = var.zone_id
  content = var.content
  proxied = var.proxied
  comment = var.comment
  ttl     = var.ttl
}
