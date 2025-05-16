variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs to associate with the route table"
  type        = list(string)
  default     = []
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

variable "tags" {
  description = "Tags to apply to the route table"
  type        = map(string)
  default     = {}
}
