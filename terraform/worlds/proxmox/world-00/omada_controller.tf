
module "omada_controller" {
  source = "../../../modules/proxmox/qemu-vm/2-9-11"

  ciuser  = "administrator"
  sshkeys = data.doppler_secrets.prod_secrets.map.HOMELAB_PUB_KEY

  config = {
    name        = "omada-controller"
    desc        = "Omada software controller for managing Omada devices. The software can be downloaded [here](https://www.tp-link.com/us/support/download/omada-software-controller/)"
    vmid        = "200"
    target_node = "proxmox-00"
    clone       = "ubuntu-focal-amd64"
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
