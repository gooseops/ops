variable "vpc_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the VPC"

}

variable "subnets" {
  type = list(object({
    cidr_block        = string
    availability_zone = string
    is_public         = bool
  }))
  description = "CIDR blocks for the subnets"
}

variable "routes" {
  description = "A list of custom route objects"
  type = list(object({
    destination_cidr_block    = string
    gateway_id                = optional(string)
    nat_gateway_id            = optional(string)
    vpc_peering_connection_id = optional(string)
    transit_gateway_id        = optional(string)
    network_interface_id      = optional(string)
    egress_only_gateway_id    = optional(string)
  }))
  default = []
}
