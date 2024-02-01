
module "jellyfin" {
    source = "../../../modules/proxmox/qemu-vm/2-9-11"

    ciuser      = "administrator"
    sshkeys     = "/home/stephen/.ssh/id_rsa.pub"

    config = {
        name        = "jellyfin"
        desc        = <<-EOT
            Jellyfin is the volunteer-built media
            solution that puts you in control of 
            your media. Stream to any device from 
            your own server, with no strings attached. 
            Your media, your server, your way.  
            Information can be found [here](https://jellyfin.org/).
        EOT
        vmid        = "206"
        target_node = "proxmox-00"
        clone       = "ubuntu-jammy-amd64"
        cores       = 1
        memory      = 1024
        sockets     = 1
        agent       = 1
        onboot      = true
        
        disk        = {
            backup      = false
            type        = "scsi"
            storage     = "local-lvm"
            size        = "60G"
            ssd         = 1
        }
        
        network     = {               
            bridge      = "vmbr0"
            firewall    = true
            model       = "virtio"
        }
    }
}
