# AWS EC2 Instance
This is a terraform module for creating all things necessary for an aws ec2 instance

## Example usage
The below files would be placed in the root/world module that is calling all submodules.

`ec2.tf`
```HCL
module "example_ec2" {
  source = "../"

  subnet_id = ["example_subnet_id"]
  security_group_ids = ["example-id1", "example-id2"]
  role = "example
  needs_eip = true
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
- `aws_instance`: AWS EC2 instance
- `aws_eip`: AWS EIP if configured to have one

## Configuration
See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Dependencies
- AWS VPC (can pass VPC ID in from the module that creates the VPC)
- AWS Security Group (can be passed in from the module that creates the sg)

## Releases
- 1.0.0: Initial Release
- 1.0.1: Variablize Cloud Init username
