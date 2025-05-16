variable "name" {
  type        = string
  default     = "foo"
  description = "Name of AWS Security Group"
}

variable "description" {
  type        = string
  default     = "An AWS Security Group"
  description = "The description of the AWS Security Group"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC where the EKS cluster will be created"
}

variable "ingress_rules" {
  type = list(object({
    name        = string
    cidr_ipv4   = string
    from_port   = number
    to_port     = number
    ip_protocol = string
  }))
}
