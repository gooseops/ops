# Illustrative-only. Real consumers pass their own pinned image alias,
# cluster target, and addressing.
module "vm" {
  source = "../"

  name           = "example-vm"
  fqdn           = "example-vm.example.internal"
  description    = "Example instance"
  cluster_target = "incus-00"
  image          = "example-debian-13"

  cpu_count      = 2
  memory         = "4GiB"
  root_disk_size = "20GiB"
  storage_pool   = "local"

  ipv4_address = "192.0.2.50"
  ipv4_prefix  = 24
  gateway      = "192.0.2.1"

  admin_user = "example-admin"
  ssh_authorized_keys = [
    "ssh-ed25519 AAAA... example",
  ]
}

output "vm_name" {
  value = module.vm.name
}

output "vm_ipv4" {
  value = module.vm.ipv4_address
}
