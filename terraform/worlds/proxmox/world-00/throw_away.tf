
# module "throw_away" {
#     source = "../../../modules/proxmox/qemu-vm/2-9-11"

#     ciuser      = "administrator"
#     sshkeys     = "/home/stephen/.ssh/id_rsa.pub"

#     config = {
#         name        = "throw-away"
#         desc        = "An ephemeral VM for testing purposes only."
#         vmid        = "254"
#         target_node = "proxmox-00"
#         clone       = "ubuntu-jammy-amd64"
#         cores       = 1
#         memory      = 1024
#         sockets     = 1
#         agent       = 1
#         onboot      = true
        
#         disk        = {
#             backup      = false
#             type        = "scsi"
#             storage     = "local-lvm"
#             size        = "10G"
#             ssd         = 1
#         }
        
#         network     = {               
#             bridge      = "vmbr0"
#             firewall    = true
#             model       = "virtio"
#         }
#     }
# }
