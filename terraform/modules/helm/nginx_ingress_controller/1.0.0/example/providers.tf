terraform {
  required_version = ">= 1.8.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
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
