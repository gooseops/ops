terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc1"
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
  alias               = "proxmox-01"
  pm_api_url          = data.doppler_secrets.prod_secrets.map.PROXMOX_API_URL_01
  pm_api_token_id     = data.doppler_secrets.prod_secrets.map.PROXMOX_API_TOKEN_ID_01
  pm_api_token_secret = data.doppler_secrets.prod_secrets.map.PROXMOX_API_TOKEN_SECRET_01
}

provider "doppler" {
  doppler_token = var.doppler_token
}

provider "cloudflare" {
  api_token = data.doppler_secrets.prod_secrets.map.CLOUDFLARE_API_TOKEN
}