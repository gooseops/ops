# resource "google_service_account" "default" {
#   account_id   = "service_account_id"
#   display_name = "Service Account"
# }

data "cloudinit_config" "conf" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = file("/home/gooseubuntu/projects/goose_projects/terraform/templates/admin_cloud_config.yaml")
    filename     = "admin_cloud_config.yaml"
  }
}

resource "google_compute_instance" "openvpn" {
  name         = "openvpn"
  machine_type = "e2-micro"
  zone         = "us-west1-a"

  tags = ["openvpn"]

  boot_disk {
    initialize_params {
      #   size = 10
      image = "ubuntu-minimal-2004-lts"
    }
  }

  network_interface {
    network = "default"
    access_config {
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
    user-data      = "${data.cloudinit_config.conf.rendered}"
  }

  #   service_account {
  #     # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
  #     email  = google_service_account.default.email
  #     scopes = ["cloud-platform"]
  #   }
}
