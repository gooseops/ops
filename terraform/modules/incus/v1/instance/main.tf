locals {
  user_data = templatefile("${path.module}/templates/user-data.yaml.tftpl", {
    hostname            = var.name
    fqdn                = var.fqdn
    admin_user          = var.admin_user
    ssh_authorized_keys = var.ssh_authorized_keys
    extra_user_data     = var.extra_user_data
  })

  network_config = templatefile("${path.module}/templates/network-config.yaml.tftpl", {
    ipv4_address = var.ipv4_address
    ipv4_prefix  = var.ipv4_prefix
    gateway      = var.gateway
    nameservers  = var.nameservers
  })

  # default is always attached first; extras append after.
  profiles = concat(["default"], var.extra_profiles)
}

resource "incus_instance" "this" {
  name        = var.name
  description = var.description
  type        = var.type
  image       = var.image
  profiles    = local.profiles
  target      = var.cluster_target

  config = merge(
    {
      "limits.cpu"           = tostring(var.cpu_count)
      "limits.memory"        = var.memory
      "cloud-init.user-data" = local.user_data
      # Bring the VM back automatically after a host reboot. Incus
      # defaults this to false, which means a hypervisor power-cycle
      # leaves every VM stopped until the operator starts each one
      # manually. Almost always undesirable for cluster nodes.
      "boot.autostart" = tostring(var.boot_autostart)
    },
    var.manage_network_in_guest ? {
      "cloud-init.network-config" = local.network_config
    } : {},
  )

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      pool = var.storage_pool
      size = var.root_disk_size
    }
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      nictype = "bridged"
      parent  = var.network_bridge
    }
  }
}
