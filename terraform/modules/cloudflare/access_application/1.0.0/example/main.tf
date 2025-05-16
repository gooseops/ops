
module "example_access_app" {
  source = "../"

  name         = "Example Access Application"
  zone_id      = "example_cf_zone_id"
  domain       = "example.com"
  email_domain = "example.com"
}
