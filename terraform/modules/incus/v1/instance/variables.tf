variable "name" {
  description = "Incus instance name. Short hostname only (Incus rejects dots); the FQDN is set inside the guest via cloud-init."
  type        = string
}

variable "fqdn" {
  description = "Fully qualified domain name written into the guest as its hostname."
  type        = string
}

variable "description" {
  description = "Free-form description shown in the Incus catalog."
  type        = string
  default     = ""
}

variable "image" {
  description = "Image alias resolved against the local Incus image store. No default on purpose — pin your own local image (see ansible/roles/incus-image-pin) rather than tracking a live upstream alias, and pass that alias here."
  type        = string
}

variable "type" {
  description = "Instance type. Either virtual-machine or container."
  type        = string
  default     = "virtual-machine"
}

variable "extra_profiles" {
  description = "Incus profiles to attach in addition to the cluster's default profile. The default profile is always attached first; entries here are appended in order. Later profiles override earlier ones on conflicting config keys or same-named devices, and instance-level config/devices override all of them."
  type        = list(string)
  default     = []
}

variable "cluster_target" {
  description = "Cluster member to place this instance on. Required in a clustered Incus deployment."
  type        = string
}

variable "cpu_count" {
  description = "Number of vCPUs."
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory limit using Incus unit suffixes (e.g. 4GiB, 8GiB)."
  type        = string
  default     = "4GiB"
}

variable "root_disk_size" {
  description = "Root disk size using Incus unit suffixes (e.g. 20GiB)."
  type        = string
  default     = "20GiB"
}

variable "storage_pool" {
  description = "Incus storage pool to land the root disk in."
  type        = string
}

variable "network_bridge" {
  description = "Host-side bridge interface the VM attaches to. Defaults to incusbr0, the conventional Incus bridge name used by the incus-host role's bridge cutover."
  type        = string
  default     = "incusbr0"
}

variable "ipv4_address" {
  description = "Static IPv4 address assigned inside the guest via cloud-init. The address is not a DHCP reservation; assumes the bridge has no Incus-managed DHCP."
  type        = string
}

variable "ipv4_prefix" {
  description = "IPv4 prefix length for the static address (e.g. 24 for a /24)."
  type        = number
  default     = 24
}

variable "gateway" {
  description = "Default gateway for the guest."
  type        = string
}

variable "nameservers" {
  description = "DNS resolvers the guest uses."
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "admin_user" {
  description = "Administrative user created in the guest via cloud-init. Receives passwordless sudo and the supplied SSH keys."
  type        = string
}

variable "ssh_authorized_keys" {
  description = "SSH public keys authorized for the admin user."
  type        = list(string)
}

variable "manage_network_in_guest" {
  description = "Render a netplan cloud-init network-config for the guest. Set false when the instance gets its address by another means (Incus-managed DHCP, NIC device ipv4.address, or operator-supplied user-data)."
  type        = bool
  default     = true
}

variable "extra_user_data" {
  description = "Optional extra cloud-init user-data appended after the rendered base. Must be a valid cloud-config fragment without the #cloud-config header."
  type        = string
  default     = ""
}

variable "boot_autostart" {
  description = "Whether the VM starts automatically when the Incus host boots. Defaults to true so a host power-cycle brings cluster VMs back without operator intervention — Incus's stock default is false. Override to false for instances that should stay stopped until explicitly started (one-off debugging VMs, decommissioning candidates)."
  type        = bool
  default     = true
}
