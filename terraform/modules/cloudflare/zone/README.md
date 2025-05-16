# Cloudflare Web Zone
This is a terraform module for creating a Cloudflare Web Zone (domain)

## Example usage
The below files would be placed in the root/world module that is calling all submodules.

`zones.tf`
```HCL
module "example_zone" {
    source = "../"

    account_id = "<<cloudflare-account-id>>"
    zone = "example.com"
}
```
`providers.tf`
```HCL
terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 4"
    }
  }
}

provider "cloudflare" {
  api_token = "<<your-api-token>>"
}
```
## Providers
See `providers.tf` of each release for minimum provider version this module supports.

- [cloudflare](https://registry.terraform.io/providers/cloudflare/cloudflare/latest)

## Resources
- `cloudflare_zone`: Cloudflare Web Zone, also known as a DNS Domain

## Configuration
See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Releases
- 1.0.0: Initial Release
