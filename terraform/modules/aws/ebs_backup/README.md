# AWS EC2 Instance
This is a terraform module for creating all things necessary for an aws ebs volume backup

## Example usage
The below files would be placed in the root/world module that is calling all submodules.

`ec2.tf`
```HCL
module "example_backup" {
  source = "../"

  iam_role_arn = "<<iam arn here>>"
  instance_arn = "<<instance arn here>>"
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
```
## Providers
See `providers.tf` of each release for minimum provider version this module supports.

- [aws](https://registry.terraform.io/providers/hashicorp/aws/latest)

## Resources
- `aws_kms_key`: AWS kms key for encryption at rest
- `aws_backup_vault`: AWS backup vault
- `aws_backup_plan`: AWS backup plan including schedule and retention
- `aws_backup_selection`: AWS backup selection of resource to backup

## Configuration
See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Releases
- 1.0.0: Initial Release
