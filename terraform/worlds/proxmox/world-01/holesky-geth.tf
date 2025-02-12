
module "holesky-geth" {
  providers = {
    proxmox = proxmox.proxmox-01
  }
  source = "../../../modules/proxmox/qemu-vm/3.0.1-rc1"

  ciuser  = "administrator"
  sshkeys = data.doppler_secrets.prod_secrets.map.HOMELAB_PUB_KEY

  config = {
    name        = "holesky-geth"
    desc        = <<-EOT
          Go Ethereum Node on Holesky testnet. Official Go implementation of the Ethereum protocol.
        See [docs](https://geth.ethereum.org/docs) for more information.
        EOT
    vmid        = "104"
    target_node = "proxmox-01"
    clone       = "ubuntu-noble-amd64"
    cores       = 32
    memory      = 16384
    sockets     = 1
    agent       = 1
    onboot      = true

    disk = {
      backup  = false
      storage = "local-lvm"
      size    = 500
      ssd     = true
    }

    network = {
      bridge   = "vmbr0"
      firewall = true
      model    = "virtio"
    }
  }
}
