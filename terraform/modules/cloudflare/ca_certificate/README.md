# Cloudflare Origin CA Cert
This is a terraform module for creating an origin CA Cert in Cloudflare

## Example usage
The below files would be placed in the root/world module that is calling all submodules.

`record.tf`
```HCL
module "example_cert" {
  source = "../"

  prvkey = "<<your private key here>>"
  common_name = "example-cert"
  organization = "example, llc"
  hostnames = [ "example.com" ]

  validity_period_hours = 24
}
```
`providers.tf`
```HCL
terraform {
  required_providers {
    tls = {
      source = "hashicorp/tls"
      version = "~> 4"
    }
  }
}
```
## Providers
See `providers.tf` of each release for minimum provider version this module supports.

- [tls](https://registry.terraform.io/providers/hashicorp/tls/latest)

## Resources
- `tls_cert_request`: Cert signing/tls cert request
- `cloudflare_origin_ca_certificate`: Origin ca cert from cloudflare

## Configuration
See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Releases
- 1.0.0: Initial Release
