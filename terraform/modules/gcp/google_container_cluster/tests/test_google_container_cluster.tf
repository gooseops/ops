module "test_google_container_cluster" {
  source = "../"

  service_account_id = "gke-service-account"
  gke_cluster_name = "test-google-container-cluster"
  # gcloud compute regions list
  location = "us-central1-a"
  deletion_protection = false
  remove_default_node_pool = true
  node_count = 1
  node_pool_name = "primary"
  preemptible = false
  machine_type = "e2-micro"
}