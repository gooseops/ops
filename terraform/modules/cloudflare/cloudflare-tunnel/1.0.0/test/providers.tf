terraform {
    required_providers {
        cloudflare = {
            source = "cloudflare/cloudflare"
            version = "~> 4.13.0"
        }
        doppler = {
            source = "DopplerHQ/doppler"
            version = ">= 1.1.2"
        }
    }
}

provider "doppler" {
    doppler_token = var.ctx_doppler_token
}


provider "cloudflare" {
    api_token  = data.doppler_secrets.autotest_secrets.map.CTX_CLOUDFLARE_API_TOKEN
}
