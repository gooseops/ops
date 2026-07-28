terraform {
  required_version = ">= 1.10"
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "~> 1.1"
    }
  }
}
