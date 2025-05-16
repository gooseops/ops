
resource "cloudflare_zone" "zone" {
  account_id = var.account_id
  zone       = var.zone
  plan       = var.plan
  type       = var.type
}
