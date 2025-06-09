# Doppler Secret
This is a terraform module for creating a Doppler Secret

## Example usage
The below files would be placed in the root/world module that is calling all submodules.

`record.tf`
```HCL
module "example_secret" {
  source = "../"
  
  doppler_project = "example-proj"
  doppler_config = "example-dev"
  secret_name = "EXAMPLE_SECRET"
  secret_value = "<<secret here>>"
}
```
`providers.tf`
```HCL
terraform {
  required_providers {
    doppler = {
      source  = "DopplerHQ/doppler"
      version = "~> 1"
    }
  }
}

provider "doppler" {
  doppler_token = "<<token here>>"
}
```
## Providers
See `providers.tf` of each release for minimum provider version this module supports.

- [doppler](https://registry.terraform.io/providers/DopplerHQ/doppler/latest)

## Resources
- `doppler_secret`: Doppler secret in specified project and config

## Configuration
See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Releases
- 1.0.0: Initial Release
