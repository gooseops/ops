
module "kubernetes_00" {
    source = "../../../modules/proxmox/qemu-vm/2-9-11"

    ciuser      = "administrator"
    sshkeys     = "/home/stephen/.ssh/id_rsa.pub"

    config = {
        name        = "kubernetes-00"
        desc        = "Kubernetes administration node."
        vmid        = "207"
        target_node = "proxmox-00"
        clone       = "ubuntu-jammy-amd64"
        cores       = 2
        memory      = 4096
        sockets     = 1
        agent       = 1
        onboot      = true
        
        disk        = {
            backup      = false
            type        = "scsi"
            storage     = "local-lvm"
            size        = "20G"
            ssd         = 1
        }
        
        network     = {               
            bridge      = "vmbr0"
            firewall    = true
            model       = "virtio"
        }
    }
}

module "kubernetes_01" {
    source = "../../../modules/proxmox/qemu-vm/2-9-11"

    ciuser      = "administrator"
    sshkeys     = "/home/stephen/.ssh/id_rsa.pub"

    config = {
        name        = "kubernetes-01"
        desc        = "Kubernetes worker node."
        vmid        = "208"
        target_node = "proxmox-00"
        clone       = "ubuntu-jammy-amd64"
        cores       = 2
        memory      = 4096
        sockets     = 1
        agent       = 1
        onboot      = true
        
        disk        = {
            backup      = false
            type        = "scsi"
            storage     = "local-lvm"
            size        = "20G"
            ssd         = 1
        }
        
        network     = {               
            bridge      = "vmbr0"
            firewall    = true
            model       = "virtio"
        }
    }
}
