
terraform {
  required_version = ">= 1.8.0"
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4"
    }
  }
}
