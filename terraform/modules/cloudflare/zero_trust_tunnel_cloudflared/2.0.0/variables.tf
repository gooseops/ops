
variable "name" {
  type        = string
  default     = "test"
  description = "The name of the Cloudflare tunnel"
}

variable "account_id" {
  type        = string
  description = "Cloudflare Account ID"
}

variable "config_src" {
  type        = string
  default     = "local"
  description = "Indicates if this is a locally or remotely configured tunnel. Available values: 'local', 'cloudflare'"
}
