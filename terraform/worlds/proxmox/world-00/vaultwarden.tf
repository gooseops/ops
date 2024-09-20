
module "vaultwarden" {
  source = "../../../modules/proxmox/qemu-vm/2-9-11"

  ciuser  = "administrator"
  sshkeys = data.doppler_secrets.prod_secrets.map.HOMELAB_PUB_KEY

  config = {
    name        = "vaultwarden"
    desc        = <<-EOT
        Vaultwarden is an unofficial Bitwarden server implementation written in Rust. It is 
        compatible with the official Bitwarden clients, and is ideal for self-hosted deployments 
        where running the official resource-heavy service is undesirable.
        EOT
    vmid        = "203"
    target_node = "proxmox-00"
    clone       = "ubuntu-noble-amd64"
    cores       = 2
    memory      = 2048
    sockets     = 1
    agent       = 1
    onboot      = true

    disk = {
      backup  = false
      type    = "scsi"
      storage = "local-lvm"
      size    = "10G"
      ssd     = 1
    }

    network = {
      bridge   = "vmbr0"
      firewall = true
      model    = "virtio"
    }
  }
}
