# Vultr instance

This is a terraform module for creating a Vultr instance.

## Example usage

`record.tf`

```HCL
module "example_instance" {
  source = "../"

  plan = var.plan
  region = var.region
  os_id = var.os_id
  label = var.label
  hostname = var.hostname
  backups = var.backups
  ssh_key_ids = var.ssh_key_ids
}
```

`providers.tf`

```HCL
terraform {
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = ">= 2.26.0"
    }
  }
}

provider "vultr" {
  api_key = "<<token here>>"
}
```

## Providers

See `providers.tf` of each release for minimum provider version this module supports.

-   [vultr](https://registry.terraform.io/providers/vultr/vultr/latest/docs)

## Resources

-   `vultr_instance`

## Configuration

See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Releases

-   1.0.0: Initial Release
