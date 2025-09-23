terraform {
  required_version = ">= 1.8.0"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.33.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.6"
    }
  }
}
