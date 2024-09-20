
# module "test" {
#   providers = {
#     proxmox = proxmox.proxmox-01
#   }
#   source = "../../../modules/proxmox/qemu-vm/3.0.1-rc1"

#   ciuser  = "administrator"
#   sshkeys = data.doppler_secrets.prod_secrets.map.HOMELAB_PUB_KEY

#   config = {
#     name        = "test"
#     desc        = <<-EOT
#             test vm
#         EOT
#     vmid        = "102"
#     target_node = "proxmox-01"
#     clone       = "ubuntu-noble-amd64"
#     cores       = 8
#     memory      = 16384
#     sockets     = 1
#     agent       = 1
#     onboot      = true

#     disk = {
#       backup  = false
#       storage = "local-zfs-sda"
#       size    = 1000
#       ssd     = true
#     }

#     network = {
#       bridge   = "vmbr0"
#       firewall = true
#       model    = "virtio"
#     }
#   }
# }
