terraform {
  required_version = ">= 1.8.0"
  required_providers {
    doppler = {
      source  = "DopplerHQ/doppler"
      version = ">= 1.6.1"
    }
  }
}
