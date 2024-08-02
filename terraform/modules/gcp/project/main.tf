
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.20.0"
    }
  }
}

provider "google" {
  region = "europe-southwest1"
  zone   = "europe-southwest1-a"
}

resource "google_project" "my_project" {
  name       = "stephen-test"
  project_id = "stephen-test-01"
}
