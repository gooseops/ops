# Illustrative-only. Real consumers live under terraform/worlds/<world>/.

# A profile that caps the QEMU memory-hotplug ceiling for VMs scheduled
# onto hosts with limited CPU physical-address bits.
module "host_legacy_cpu" {
  source = "../"

  name        = "host-legacy-cpu"
  description = "Cap maxmem for VMs on 36-phys-bit hosts."

  config = {
    "raw.qemu.conf" = <<-EOT
      [memory]
      maxmem = "4G"
    EOT
  }
}

# A profile that overrides the default root disk pool. Demonstrates the
# devices input — useful for grouping VMs onto a faster pool without
# repeating the override on every instance.
module "fast_root" {
  source = "../"

  name        = "fast-root"
  description = "Place root disks on the nvme storage pool."

  devices = [
    {
      name = "root"
      type = "disk"
      properties = {
        path = "/"
        pool = "nvme"
      }
    },
  ]
}
