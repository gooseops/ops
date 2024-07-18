
provider "google" {
  credentials = file(var.credentials_file)

  project = var.project_id
  #   region  = "us-central1"
  #   zone    = "us-central1-c"
}
