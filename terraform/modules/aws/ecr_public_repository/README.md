# AWS Elastic Container Registry Repository
This is a terraform module for creating all things necessary for an aws ecr repository

## Example usage
The below files would be placed in the root/world module that is calling all submodules.

`public_ecr_repos.tf`
```HCL
module "test_public_ecr" {
    providers = {
        aws = aws.us-east-1
    }

    source = "../"
    repository_name = "foo"
}
```
`providers.tf`
```HCL
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }
  }
}

provider "aws" {
    alias = "us-east-1"
    region = "us-east-1"
}

provider "aws" {
    alias = "us-east-2"
    region = "us-east-2"
}
```
## Providers
See `providers.tf` of each release for minimum provider version this module supports.

- [aws](https://registry.terraform.io/providers/hashicorp/aws/latest)

## Resources
- `aws_ecr_repository`: AWS Elastic Container Registry Repository for storing container images
- `aws_ecrpublic_repository_policy`: AWS Elastic Container Registry Repository for allowing other users to push to the registry.

## Configuration
See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Releases
- 1.0.0: Initial Release
