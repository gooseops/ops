module "example-node-1" {
  source = "../"

  name           = "example-node-1"
  machine_type   = "e2-micro"
  zone           = "europe-southwest1-a"
  tags           = ["example"]
  compute_image  = "ubuntu-2204-jammy-v20230302"
  boot_disk_size = 20
  admin_pubkey   = "ssh pubkey here"
  admin_user     = "example-user"
}
