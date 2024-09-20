
resource "cloudflare_record" "record" {
  name    = var.name
  type    = var.type
  zone_id = var.zone_id
  content = var.content
  proxied = var.proxied
}
