
module "bibox_vm" {
  providers = {
    proxmox = proxmox.proxmox-01
  }
  source = "../../../modules/proxmox/qemu-vm/3.0.1-rc1"

  ciuser  = "administrator"
  sshkeys = "/home/stephen/.ssh/id_rsa.pub"

  config = {
    name        = "bigbox"
    desc        = <<-EOT
            bigbox devbox
        EOT
    vmid        = "100"
    target_node = "proxmox-01"
    clone       = "ubuntu-jammy-amd64"
    cores       = 32
    memory      = 61440
    sockets     = 1
    agent       = 1
    onboot      = true

    disk = {
      backup  = false
      storage = "local-lvm"
      size    = 1000
      ssd     = true
    }

    network = {
      bridge   = "vmbr0"
      firewall = true
      model    = "virtio"
    }
  }
}
