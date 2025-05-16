# Cloudflare Access Application
This is a terraform module for creating a Cloudflare Access Application

## Example usage
The below files would be placed in the root/world module that is calling all submodules.

`access_apps.tf`
```HCL
module "example_access_app" {
  source = "../"

  name = "Example Access Application"
  zone_id = "example_cf_zone_id"
  domain = "example.com"
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
- `cloudflare_access_policy`: A Cloudflare Access Policy that allows all users with a domain specific email address to access the the access application created by this module.
- `cloudflare_access_application`: A Cloudflare Access Application that sets up authentication in front of a specificied domain allowing Cloudflare to easily handle securing the domain.

## Configuration
See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Releases
- 1.0.0: Initial Release
