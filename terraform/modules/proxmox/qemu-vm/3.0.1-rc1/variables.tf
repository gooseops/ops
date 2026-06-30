variable "ciuser" {
  type = string
}

variable "sshkeys" {
  type = string
}

variable "name" {
  type = string
}

variable "desc" {
  type = string
}

variable "vmid" {
  type = number
}

variable "target_node" {
  type = string
}

variable "clone" {
  type = string
}

variable "cores" {
  type = number
}

variable "memory" {
  type = number
}

variable "sockets" {
  type = number
}

variable "agent" {
  type = number
}

variable "onboot" {
  type = bool
}

variable "network_bridge" {
  type = string
}

variable "network_firewall" {
  type = bool
}

variable "network_model" {
  type = string
}

variable "single_disk" {
  type        = bool
  description = "Whether the vm only has a single disk"
  default     = true
}

variable "single_disk_storage" {
  type        = string
  description = "Which type of storage for single disk"
  default     = "local-lvm"
}

variable "single_disk_size" {
  type        = number
  description = "Size in GB of the only disk"
  default     = 10
}

variable "single_disk_ssd" {
  type        = bool
  description = "Whether or not to treat the drive as an ssd"
  default     = true
}

# variable "disk" {
#   type = object({
#     storage = string
#     size    = number
#     ssd     = bool
#   })
#   default = null
# }
