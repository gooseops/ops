
resource "proxmox_vm_qemu" "proxmox-vm" {

  ciuser                  = var.ciuser
  sshkeys                 = file(var.sshkeys)
  qemu_os                 = null
  name                    = var.config.name
  target_node             = var.config.target_node
  vmid                    = var.config.vmid
  desc                    = var.config.desc
  onboot                  = var.config.onboot
  agent                   = var.config.agent
  clone                   = var.config.clone
  memory                  = var.config.memory
  sockets                 = var.config.sockets
  cores                   = var.config.cores
  ipconfig0               = "ip=192.168.1.${var.config.vmid}/16,gw=192.168.0.1"
  cloudinit_cdrom_storage = "local-lvm"

  scsihw = "virtio-scsi-pci"
  boot   = "order=scsi0;ide3"
  disks {
    scsi {
      scsi0 {
        disk {
          storage    = var.config.disk.storage
          size       = var.config.disk.size
          emulatessd = var.config.disk.ssd
        }
      }
    }
  }

  network {
    bridge   = var.config.network.bridge
    firewall = var.config.network.firewall
    model    = var.config.network.model
  }
}