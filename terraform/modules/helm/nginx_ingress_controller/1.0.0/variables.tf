variable "namespace" {
  type        = string
  default     = "ingress-nginx"
  description = "The Kubernetes namespace to deploy the NGINX Ingress Controller"
}

variable "chart_version" {
  type        = string
  default     = "4.12.1"
  description = "The version of the NGINX Ingress Controller Helm chart"
}

variable "service_type" {
  type        = string
  default     = "LoadBalancer"
  description = "The type of service for the NGINX Ingress Controller"
}

variable "values" {
  type        = string
  default     = ""
  description = "Custom values to override the default Helm chart values"
}
