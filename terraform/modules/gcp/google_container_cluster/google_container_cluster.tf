resource "google_service_account" "default" {
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
  disabled     = var.service_account_is_disabled
}

resource "google_container_cluster" "gke_cluster" {
  name                = var.gke_cluster_name
  location            = var.location
  deletion_protection = var.deletion_protection
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = var.remove_default_node_pool
  initial_node_count       = var.initial_node_count
}

## needs to be a for each block to take in multiple node pools
resource "google_container_node_pool" "node_pool" {
  name       = "${var.gke_cluster_name}-${var.node_pool_name}"
  location   = var.location
  cluster    = google_container_cluster.gke_cluster.name
  node_count = var.node_count

  node_config {
    preemptible  = var.preemptible
    machine_type = var.machine_type

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
