terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 2.9.11"
    }
    doppler = {
      source  = "DopplerHQ/doppler"
      version = "~> 1.6.1"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4"
    }
  }
}

provider "proxmox" {
  pm_api_url          = data.doppler_secrets.prod_secrets.map.PROXMOX_API_URL
  pm_api_token_id     = data.doppler_secrets.prod_secrets.map.PROXMOX_API_TOKEN_ID
  pm_api_token_secret = data.doppler_secrets.prod_secrets.map.PROXMOX_API_TOKEN_SECRET
}

provider "doppler" {
  doppler_token = var.doppler_token
}

provider "cloudflare" {
  api_token = data.doppler_secrets.prod_secrets.map.CLOUDFLARE_API_TOKEN
}