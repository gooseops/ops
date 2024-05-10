
module "osmosis" {
    source = "../../../modules/proxmox/qemu-vm/2-9-11"

    ciuser      = "administrator"
    sshkeys     = "/home/stephen/.ssh/id_rsa.pub"

    config = {
        name        = "osmosis"
        desc        = <<-EOT
            vm for testing osmosis playbooks.
        EOT
        vmid        = "210"
        target_node = "proxmox-00"
        clone       = "ubuntu-jammy-amd64"
        cores       = 4
        memory      = 4096
        sockets     = 1
        agent       = 1
        onboot      = true
        
        disk        = {
            backup      = false
            type        = "scsi"
            storage     = "local-lvm"
            size        = "50G"
            ssd         = 1
        }
        
        network     = {               
            bridge      = "vmbr0"
            firewall    = true
            model       = "virtio"
        }
    }
}
