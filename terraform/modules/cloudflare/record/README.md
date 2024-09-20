# Cloudflare DNS Record
This is a terraform module for creating a DNS record in Cloudflare

## Example usage
The below files would be placed in the root/world module that is calling all submodules.

`record.tf`
```HCL
module "example_record" {
  source = "../"

  type = "CNAME"
  name = "*.example_subdomain"
  zone_id = data.cloudflare_zone.example.zone_id
  value   = data.kubernetes_service.example.status.0.load_balancer.0.ingress.0.hostname
  ttl     = 3600
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
  api_token = "<<api-token>>"
}
```
## Providers
See `providers.tf` of each release for minimum provider version this module supports.

- [cloudflare](https://registry.terraform.io/providers/cloudflare/cloudflare/latest)

## Resources
- `cloudflare_record`: Cloudflare DNS record

## Outputs
- `hostname`: The domain/hostname the record is created for

## Configuration
See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Releases
- 1.0.0: Initial Release
