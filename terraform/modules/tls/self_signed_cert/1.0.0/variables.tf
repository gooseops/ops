variable "prvkey" {
  type        = string
  description = "TLS private key"
}

variable "allowed_uses" {
  type        = set(string)
  default     = []
  description = "What the cert will be allowed to be used for"
}

variable "validity_period_hours" {
  type        = number
  default     = 43800
  description = "Length of time in hours that the certificate will be valid for"
}

variable "common_name" {
  type        = string
  description = "Arbitrary name of the ca certificate, can't be an IP"
}

variable "organization" {
  type        = string
  description = "Name of organization that will own the certificate"
}

variable "hostnames" {
  type        = set(string)
  description = "List of hostnames that the certificate will validate"
}

variable "ip_addresses" {
  type        = set(string)
  default     = []
  description = "SAN IP addresses for cert"
}

variable "is_ca_certificate" {
  type        = bool
  default     = true
  description = "Whether certificate is a root CA"
}

variable "set_authority_key_id" {
  type        = bool
  default     = true
  description = "Whether to add Authority Key extention"
}

variable "set_subject_key_id" {
  type        = bool
  default     = true
  description = "Whether to add Subject Key extension"
}
