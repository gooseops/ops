terraform {
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = ">= 2.26.0"
    }
  }
}

provider "vultr" {
  api_key = "<<token here>>"
}
