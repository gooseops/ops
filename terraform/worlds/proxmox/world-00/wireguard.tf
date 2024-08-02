
module "wireguard" {
  source = "../../../modules/proxmox/qemu-vm/2-9-11"

  ciuser  = "administrator"
  sshkeys = data.doppler_secrets.prod_secrets.map.HOMELAB_PUB_KEY

  config = {
    name        = "wireguard"
    desc        = <<-EOT
            WireGuard® is an extremely simple yet fast and modern VPN that utilizes 
            state-of-the-art cryptography. It aims to be faster, simpler, leaner, and more 
            useful than IPsec, while avoiding the massive headache. It intends to be 
            considerably more performant than OpenVPN. WireGuard is designed as a general purpose 
            VPN for running on embedded interfaces and super computers alike, fit for many 
            different circumstances. Initially released for the Linux kernel, it is now 
            cross-platform (Windows, macOS, BSD, iOS, Android) and widely deployable. It is 
            currently under heavy development, but already it might be regarded as the most secure,
            easiest to use, and simplest VPN solution in the industry.
        EOT
    vmid        = "202"
    target_node = "proxmox-00"
    clone       = "debian-bookworm-amd64"
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
