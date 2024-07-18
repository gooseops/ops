
variable "namespace" {
  type        = string
  default     = null
  description = "The optional namespace for helmcharts to be deployed to"
}

## kube-metrics helm release configuration variables
variable "is_metrics_server_enabled" {
  type    = bool
  default = false
}

## traefik helm release configuration variables
variable "is_traefik_enabled" {
  type    = bool
  default = false
}
