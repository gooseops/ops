terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "2.9.11"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.api_url
  pm_api_token_id     = var.api_token_id
  pm_api_token_secret = var.api_token_secret
}