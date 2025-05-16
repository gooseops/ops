
data "template_file" "cloud_init" {
  template = file("${path.module}/templates/cloud_config.yaml")

  vars = {
    admin_user   = var.admin_user
    admin_pubkey = var.admin_pubkey
  }
}

# Provision a static ip for the node
resource "google_compute_address" "static_ip" {
  name = var.name
}

resource "google_compute_disk" "boot_disk" {
  name  = "${var.name}-boot-disk"
  type  = var.boot_disk_type
  zone  = var.zone
  size  = var.boot_disk_size
  image = var.compute_image
}

# Provision the node
resource "google_compute_instance" "compute_instance" {
  name         = var.name
  project      = var.project
  machine_type = var.machine_type
  zone         = var.zone
  tags         = var.tags

  allow_stopping_for_update = var.allow_stopping_for_update

  metadata = {
    enable-oslogin = var.enable_oslogin
    user-data      = data.template_file.cloud_init.rendered
  }

  boot_disk {
    source = google_compute_disk.boot_disk.self_link
  }

  network_interface {
    network = var.network

    # Include this section to give the VM an external IP address
    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }
}
