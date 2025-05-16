# Cloudflare Tunnel
This is a terraform module for creating a Cloudflare Tunnel

## Example usage
The below files would be placed in the root/world module that is calling all submodules.

`tunnels.tf`
```HCL
module "example_tunnel" {
  source = "../"

  name = "example-tunnel"
  account_id = "<<your account id here>>"
}
```
`providers.tf`
```HCL
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
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
- `random_id`: A random string converted to hex that serves as the cloudflare tunnel auth string
- `cloudflare_tunnel`: Cloudflare Tunnel for allowing access to web servers without port opening/forwarding

## Configuration
See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Releases
- 1.0.0: Initial Release
