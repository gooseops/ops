
variable "cloudflare_account_id" {
  type        = string
  description = "Cloudflare Account ID"
}

variable "tunnel_name" {
  type        = string
  default     = "test"
  description = "The name of the Cloudflare tunnel"
}

variable "config_src" {
  type        = string
  default     = "local"
  description = "`local` or `cloudflare`"
}
