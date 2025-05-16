terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.46"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.3"
    }
  }
}
