resource "incus_profile" "this" {
  name        = var.name
  description = var.description
  project     = var.project

  config = var.config

  dynamic "device" {
    for_each = var.devices
    content {
      name       = device.value.name
      type       = device.value.type
      properties = device.value.properties
    }
  }
}
