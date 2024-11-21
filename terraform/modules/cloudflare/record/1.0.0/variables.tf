variable "name" {
  type        = string
  description = "Name of the record usually a subdomain. (i.e. 'example')"
}

variable "type" {
  type        = string
  default     = "CNAME"
  description = "Type of DNS record"
}

variable "zone_id" {
  type        = string
  description = "The zone id of the domain being managed"
}

variable "content" {
  type        = string
  description = "The content of the DNS record entry, usually an ip or dns name."
}

variable "proxied" {
  type        = bool
  default     = true
  description = "Whether or not the DNS resolution is proxied"
}

variable "comment" {
  type = string
  default = "Terraform Managed"
  description = "The comment to include with the DNS record"
}
