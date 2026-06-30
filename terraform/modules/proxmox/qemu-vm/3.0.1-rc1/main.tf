
resource "proxmox_vm_qemu" "proxmox-vm" {
  count                   = var.single_disk ? 1 : 0
  ciuser                  = var.ciuser
  sshkeys                 = var.sshkeys
  qemu_os                 = "other"
  name                    = var.name
  target_node             = var.target_node
  vmid                    = var.vmid
  desc                    = var.desc
  onboot                  = var.onboot
  agent                   = var.agent
  clone                   = var.clone
  memory                  = var.memory
  sockets                 = var.sockets
  cores                   = var.cores
  ipconfig0               = "ip=192.168.1.${var.vmid}/16,gw=192.168.0.1"
  cloudinit_cdrom_storage = "local-lvm"

  scsihw = "virtio-scsi-pci"
  boot   = "order=scsi0;ide3"

  network {
    bridge   = var.network_bridge
    firewall = var.network_firewall
    model    = var.network_model
  }

  disks {
    scsi {
      scsi0 {
        disk {
          storage    = var.single_disk_storage
          size       = var.single_disk_size
          emulatessd = var.single_disk_ssd
        }
      }
    }
  }

}

# resource "proxmox_vm_qemu" "proxmox-vm-multi-disk" {
#   count                   = var.single_disk ? 0 : 1
#   ciuser                  = var.ciuser
#   sshkeys                 = var.sshkeys
#   qemu_os                 = "other"
#   name                    = var.name
#   target_node             = var.target_node
#   vmid                    = var.vmid
#   desc                    = var.desc
#   onboot                  = var.onboot
#   agent                   = var.agent
#   clone                   = var.clone
#   memory                  = var.memory
#   sockets                 = var.sockets
#   cores                   = var.cores
#   ipconfig0               = "ip=192.168.1.${var.vmid}/16,gw=192.168.0.1"
#   cloudinit_cdrom_storage = "local-lvm"

#   scsihw = "virtio-scsi-pci"
#   boot   = "order=scsi0;ide3"

#   network {
#     bridge   = var.network_bridge
#     firewall = var.network_firewall
#     model    = var.network_model
#   }

#   disk {
#     type        = "disk"
#     slot        = "scsi0"
#     storage    = var.single_disk_storage
#     size       = var.single_disk_size
#     emulatessd = var.single_disk_ssd
#   }

# }
