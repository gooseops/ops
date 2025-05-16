# Nginx Ingress Controller Helm Release
This is a terraform module for creating an Nginx Ingress Controller Helm Release.

## Example usage
The below files would be placed in the root/world module that is calling all submodules.

`nginx_ingress.tf`
```HCL
module "example_ingress_nginx" {
    source = "../"
}
```
`providers.tf`
```HCL
terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "~> 2"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = "<<k8s-host>>"
    client_certificate     = "<<k8s-client-cert>>"
    client_key             = "<<k8s-client-key>>"
    cluster_ca_certificate = "<<k8s-cluster-ca-cert>>"
  }
}
```
## Providers
See `providers.tf` of each release for minimum provider version this module supports.

- [helm](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)

## Resources
- `helm_release`: A Helm Release of the Nginx Ingress Controller

## Configuration
See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Releases
- 1.0.0: Initial Release
