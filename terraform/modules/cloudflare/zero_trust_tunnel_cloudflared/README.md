# Cloudflare Tunnel
This is a terraform module for creating a Cloudflare Tunnel

## Examples
Please see the `example` directory in each module version for ways the module can be used in a worlds directory.

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
- 2.0.0: Updated provider to version 5
