
module "dev-dro-operator" {
  providers = {
    proxmox = proxmox.proxmox-01
  }
  source = "../../../modules/proxmox/qemu-vm/3.0.1-rc1"

  ciuser  = "administrator"
  sshkeys = data.doppler_secrets.prod_secrets.map.HOMELAB_PUB_KEY

  config = {
    name        = "dev-dro-operator"
    desc        = <<-EOT
            [docs](https://dev.drosera.io)
        EOT
    vmid        = "102"
    target_node = "proxmox-01"
    clone       = "ubuntu-noble-amd64"
    cores       = 2
    memory      = 4096
    sockets     = 1
    agent       = 1
    onboot      = true

    disk = {
      backup  = false
      storage = "local-lvm"
      size    = 40
      ssd     = true
    }

    network = {
      bridge   = "vmbr0"
      firewall = true
      model    = "virtio"
    }
  }
}
