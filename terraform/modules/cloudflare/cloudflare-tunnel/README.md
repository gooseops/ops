# Cloudflare Tunnel
This is a terraform module for creating a Cloudflare Tunnel

## Example usage
The below files would be placed in the root/world module that is calling all submodules.

`tunnels.tf`
```HCL
module "example_tunnel" {
  source = "../"

  cloudflare_account_id = <cloudflare account id here>
  tunnel_name = "example"
}
```
`providers.tf`
```HCL
terraform {
  required_providers {
    tls = {
      source = "hashicorp/tls"
      version = "~> 5"
    }
  }
}
```
## Providers
See `providers.tf` of each release for minimum provider version this module supports.

- [cloudflare](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)

## Resources
- `random_id`: Tunnel secret for authenticating the cloudflare tunnel
- `cloudflare_tunnel`: Cloudflare tunnel

## Configuration
See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Releases
- 1.0.0: Initial Release
- 2.0.0:
  - Moved to Cloudflare Terraform Provider `>= 5.0`
  - Removed randomized names for simplicity
  - Removed local conversion to dns safe string
