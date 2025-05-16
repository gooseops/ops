variable "eks_oidc_issuer" {
  type        = string
  description = "Issuer of OIDC tls certs"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster to attach addon to"
}

variable "eks_csi_driver_version" {
  type        = string
  description = "Version of the csi driver to install"
}
