resource "doppler_secret" "secret" {
  project = var.doppler_project
  config = var.doppler_config
  name = var.secret_name
  value = var.secret_value
}
