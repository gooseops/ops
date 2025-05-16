# AWS Security Group
This is a terraform module for creating all things necessary for an aws security group

## Example usage
The below files would be placed in the root/world module that is calling all submodules.

`security_group.tf`
```HCL
module "example_sg" {
  source = "../"

  name   = "example_sg"
  vpc_id = "example_vpc_id"
  ingress_rules = [
    {
      name = "http"
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
    }
  ]

  depends_on = ["example-dependency-1", "example-dependency-2"]
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
- `aws_security_group`: AWS Security Group for managing and limiting public internet access to the EKS Cluster
- `aws_vpc_security_group_ingress_rule`: AWS Ingress rule applied to the created security group.
- `aws_vpc_security_group_egress_rule`: AWS Egress rule applied to the created security group. Currently hardcoded to allow all egress traffic.

## Configuration
See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Dependencies
- AWS VPC (can pass VPC ID in from the module that creates the VPC)

## Releases
- 1.0.0: Initial Release
