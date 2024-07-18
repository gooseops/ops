
module "test" {
  source = "../../../modules/proxmox/qemu-vm/2-9-11"

  ciuser  = "administrator"
  sshkeys = "/home/stephen/.ssh/gooseops-laptop.pub"

  config = {
    name        = "test"
    desc        = <<-EOT
            test
        EOT
    vmid        = "225"
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
