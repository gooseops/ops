
variable "name" {
  type        = string
  default     = "test"
  description = "The name of the Cloudflare tunnel"
}

variable "account_id" {
  type        = string
  description = "Cloudflare Account ID"
}
