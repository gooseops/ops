module "example_secret" {
  source = "../"

  doppler_project = "example-proj"
  doppler_config  = "example-dev"
  secret_name     = "EXAMPLE_SECRET"
  secret_value    = "<<secret here>>"
}
