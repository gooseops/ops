terraform {
  required_providers {
    doppler = {
      source  = "DopplerHQ/doppler"
      version = "~> 1"
    }
  }
}

provider "doppler" {
  doppler_token = "<<token here>>"
}
