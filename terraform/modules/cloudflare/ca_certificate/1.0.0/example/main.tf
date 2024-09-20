module "example_cert" {
  source = "../"

  prvkey       = "<<your private key here>>"
  common_name  = "example-cert"
  organization = "example, llc"
  hostnames    = ["example.com"]

}
