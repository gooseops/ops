
resource "cloudflare_zero_trust_access_application" "app" {
  zone_id          = var.zone_id
  name             = var.name
  domain           = var.domain
  session_duration = var.session_duration
}

resource "cloudflare_zero_trust_access_policy" "policy" {
  name    = "Allow Domain Specific Users"
  zone_id = var.zone_id

  application_id = cloudflare_zero_trust_access_application.app.id
  precedence     = 1
  decision       = "allow"

  include {
    email_domain = var.email_domain
  }

  require {
    email_domain = var.email_domain
  }
}
