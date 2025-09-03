
module "example_dns_record" {
  source = "../"

  name    = "example-subdomain"
  type    = "CNAME"
  zone_id = "<<your-zone-id>>"
  value   = "example.com"
}
