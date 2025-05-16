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
