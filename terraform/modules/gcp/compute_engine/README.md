# GCP Compute Instance
This is a terraform module for creating all things necessary for a Compute instance in GCP

## Examples
Please see the `example` directory in each moduel version for ways the module can be used in a worlds directory

## Providers
See [providers.tf](./providers.tf) for minimum provider version this module supports.

- [google](https://registry.terraform.io/providers/hashicorp/google/latest)

## Resources
- `google_compute_address`:  Static public IPv4 address to attach to the node
- `google_compute_disk`: Separately provisioned disk as the boot disk of the instance
- `google_compute_instance`: GCP compute instance (vm)

## Configuration
See [variables.tf](./variables.tf) for variable configuration, defaults, and descriptions about the available configurations for this module.

## Releases
- 1.0.0: Initial Release
