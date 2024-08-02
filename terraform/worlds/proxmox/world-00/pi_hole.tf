
module "pi_hole" {
  source = "../../../modules/proxmox/qemu-vm/2-9-11"

  ciuser  = "administrator"
  sshkeys = data.doppler_secrets.prod_secrets.map.HOMELAB_PUB_KEY

  config = {
    name        = "pi-hole"
    desc        = "Pi-hole is a Linux network-level advertisement and Internet tracker blocking application which acts as a DNS sinkhole and optionally a DHCP server, intended for use on a private network.  Information can be found [here](https://pi-hole.net/)."
    vmid        = "201"
    target_node = "proxmox-00"
    clone       = "ubuntu-jammy-amd64"
    cores       = 1
    memory      = 512
    sockets     = 1
    agent       = 1
    onboot      = true

    disk = {
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
