# AWS IAM Role
This is a terraform module for creating all things necessary for an aws IAM Role

## Example usage
The below files would be placed in the root/world module that is calling all submodules.

`iam_roles.tf`
```HCL
module "example_role" {
  source = "../../modules/aws/iam_node_role/1.0.0"

  role_name          = "eks-cluster"
  assume_role_policy = <<-EOT
  {
    "Statement": [{
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      }
    }],
    "Version": "2012-10-17"
  }
  EOT
  policy_attachment_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
  ]
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
    region = "us-east-2"
}
```
## Providers
See `providers.tf` of each release for minimum provider version this module supports.

- [aws](https://registry.terraform.io/providers/hashicorp/aws/latest)

## Resources
- `aws_iam_role`: AWS IAM Role for granting permissions and access to different resources
- `aws_iam_role_policy_attachment`: AWS IAM Role Policy Attachments to add AWS Managed policies to the Role being created.

## Configuration
See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Releases
- 1.0.0: Initial Release
