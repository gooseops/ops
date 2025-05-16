# modules/vpc_peering/variables.tf
variable "requester_vpc_id" {
  type        = string
  description = "The ID of the requester VPC"
}

variable "accepter_vpc_id" {
  type        = string
  description = "The ID of the accepter VPC"
}

variable "accepter_region" {
  type        = string
  description = "Region of the accepter VPC"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to the peering connection"
}
