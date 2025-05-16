
variable "name" {
  type        = string
  description = "Cloudflare Access Application Name"
}

variable "zone_id" {
  type        = string
  description = "Cloudflare Zone ID for domain that application is served on"
}

variable "domain" {
  type        = string
  description = "Full domain (including subdomain) that cloudflare application is served on"
}

variable "session_duration" {
  type        = string
  default     = "24h"
  description = "Authorization duration"
}

variable "email_domain" {
  type        = list(string)
  description = "List of email domains to allow access for"
}
