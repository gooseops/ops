variable "name" {
  type        = string
  description = "Name of the recordm usually a subdomain. (i.e. 'exmaple')"
}

variable "type" {
  type        = string
  default     = "CNAME"
  description = "Type of DNS record"
}

variable "zone_id" {
  type        = string
  description = "The zone id of the domain being managed.  Usually passed in as a data object."
}

variable "value" {
  type        = string
  description = "The value of the DNS record entry, usually an ip or dns name."
}

variable "proxied" {
  type        = bool
  default     = true
  description = "Whether or not the DNS resolution is proxied"
}

variable "ttl" {
  type        = number
  default     = 1
  description = "Time To Live (TTL) of the DNS record in seconds. Setting to 1 means 'automatic'."
}
