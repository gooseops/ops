terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6"
    }
  }
}

provider "google" {
  project = "example-project"
  region  = "example-region"
}
