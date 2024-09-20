variable "prvkey" {
  type        = string
  description = "TLS private key"
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
variable "requested_validity" {
  type        = number
  default     = 365
  description = "Length of time in days that the certificate will be valid for"
}

variable "request_type" {
  type        = string
  default     = "origin-rsa"
  description = "The type of certificate being requested"
}
