module "example_instance" {
  source = "../"

  plan          = "vc2-1c-2gb"
  region        = "sea"
  os_id         = 1743
  label         = "my-instance-label"
  hostname      = "my-instance-hostname"
  backups       = "enabled"
  vultr_api_key = "<<token here>>"
}
