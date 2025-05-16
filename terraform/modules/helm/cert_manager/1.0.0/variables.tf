variable "namespace" {
  type        = string
  default     = "cert-manager"
  description = "The Kubernetes namespace to deploy the NGINX Ingress Controller"
}

variable "chart_version" {
  type        = string
  default     = "v1.15.0"
  description = "The version of the NGINX Ingress Controller Helm chart"
}

variable "values" {
  type        = string
  default     = ""
  description = "Custom values to override the default Helm chart values"
}
