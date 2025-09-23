terraform {
  required_version = ">= 1.8.0"
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = ">= 2.26.0"
    }
  }
}
