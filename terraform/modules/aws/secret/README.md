# AWS EC2 AWS Secrets Manager Secret and Version
This is a terraform module for creating all things necessary to create an AWS Secrets Manager secret and version for storing secrets and variables that terraform manages but are needed elsewhere.

## Example usage
The below files would be placed in the root/world module that is calling all submodules.

`aws_secrets.tf`
```HCL
module "example_aws_secret" {
  source = "../"

  secret_name = "example"
  secret_string = "foobar"
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
- `aws_secretsmanager_secret`: AWS Secret declaration
- `aws_secretsmanager_secret_version`: AWS Secret definition of the secret declaration

## Configuration
See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Dependencies
- None

## Releases
- 1.0.0: Initial Release
