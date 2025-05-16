
variable "account_id" {
  type        = string
  default     = ""
  description = "Cloudflare account id"
}

variable "zone" {
  type        = string
  default     = "example.com"
  description = "Cloudflare domain name to manage"
}

variable "plan" {
  type        = string
  default     = "free"
  description = "The name of the commercial plan to apply to the zone"
}

variable "type" {
  type        = string
  default     = "full"
  description = <<-EOF
    A full zone implies that DNS is hosted with Cloudflare.
    A partial zone is typically a partner-hosted zone or a CNAME setup.
  EOF
}
