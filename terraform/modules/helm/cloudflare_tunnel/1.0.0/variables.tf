
variable "namespace" {
  type        = string
  default     = null
  description = "The optional namespace for helmcharts to be deployed to"
}

variable "cloudflare_tunnel" {
  type = object({
    account_id   = string,
    cname        = string,
    id           = string,
    name         = string,
    secret       = string,
    tunnel_token = string
  })
  default     = null
  description = <<EOF
    This map is typically defined by the outputs of other modules and does not need to be set
    manually.
    EOF
}

variable "domains" {
  type        = list(string)
  default     = []
  description = <<EOF
    A list of domains that will eventually be passed into the cloudflared 
    config.yml ingress block
    EOF
}
