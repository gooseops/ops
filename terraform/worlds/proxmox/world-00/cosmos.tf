
# module "cosmos" {
#     source = "../../../modules/proxmox/qemu-vm/2-9-11"

#     ciuser      = "administrator"
#     sshkeys     = "/home/stephen/.ssh/id_rsa.pub"

#     config = {
#         name        = "cosmos"
#         desc        = "A Comsos sandbox. See [here](https://tutorials.cosmos.network/academy/1-what-is-cosmos/) for details"
#         vmid        = "204"
#         target_node = "proxmox-00"
#         clone       = "ubuntu-jammy-amd64"
#         cores       = 2
#         memory      = 4096
#         sockets     = 1
#         agent       = 1
#         onboot      = true
        
#         disk        = {
#             backup      = false
#             type        = "scsi"
#             storage     = "local-lvm"
#             size        = "30G"
#             ssd         = 1
#         }
        
#         network     = {               
#             bridge      = "vmbr0"
#             firewall    = true
#             model       = "virtio"
#         }
#     }
# }
