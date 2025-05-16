terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.46"
      configuration_aliases = [aws.requester, aws.accepter]
    }
  }
}
