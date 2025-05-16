
module "example_zone" {
  source = "../"

  account_id = "<<cloudflare-account-id>>"
  zone       = "example.com"
}
