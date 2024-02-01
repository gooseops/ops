variable "ciuser" {
    type = string
}

variable "sshkeys" {
    type = string
}

variable "config" {
    type = object({
        name        = string
        desc        = string
        vmid        = number
        target_node = string
        clone       = string
        cores       = number
        memory      = number
        sockets     = number
        agent       = number
        onboot      = bool
        disk        = object({
            type        = string
            storage     = string
            size        = string
            ssd         = number
        })
        network     = object({
            bridge      = string
            firewall    = bool
            model       = string
        })
    })
}