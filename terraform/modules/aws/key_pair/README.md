# AWS EC2 AWS Key Pair
This is a terraform module for creating all things necessary to create an EC2 AWS Key Pair for configuring ssh access to EC2 instances

## Example usage
The below files would be placed in the root/world module that is calling all submodules.

`aws_key_pairs.tf`
```HCL
module "example_aws_key_pair" {
  source = "../"

  sshkey_prefix = "example"
  public_key = "public key content here"
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
  region = "us-east-2"
}
```
## Providers
See `providers.tf` of each release for minimum provider version this module supports.

- [aws](https://registry.terraform.io/providers/hashicorp/aws/latest)

## Resources
- `aws_key_pair`: AWS Key Pair with the public key as the input for use with configuring ssh access to EC2 instances

## Configuration
See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Dependencies
- None

## Releases
- 1.0.0: Initial Release
