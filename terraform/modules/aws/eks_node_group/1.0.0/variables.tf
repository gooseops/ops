variable "eks_ami" {
  type    = string
  default = "ami-1234567890abcdef"
}

variable "instance_type" {
  type        = string
  default     = "t3.medium"
  description = "Instance type for nodes+"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of the security group ids to apply to node group"
}

variable "node_group_name" {
  type        = string
  description = "Name of node group"
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "disk_size" {
  type        = number
  default     = 20
  description = "Size of EC2 disk"
}

variable "volume_type" {
  type        = string
  default     = "gp3"
  description = "Type of volume for node disks"
}

variable "node_role_arn" {
  type        = string
  description = "The AWS ARN of the node group role for provisioning EKS nodes."
}

variable "subnet_ids" {
  type        = list(string)
  default     = []
  description = "List of subnet IDs where the EKS cluster will be created"
}

variable "capacity_type" {
  type        = string
  default     = "ON_DEMAND"
  description = "Type of EC2 capacity"
}

variable "node_labels" {
  type = object({})
}

variable "desired_size" {
  type        = number
  default     = 1
  description = "Desired number of nodes in node group"
}

variable "max_size" {
  type        = number
  default     = 2
  description = "Maximum number of nodes in node group"
}

variable "min_size" {
  type        = number
  default     = 1
  description = "Minimum number of nodes in node group"
}

variable "max_unavailable" {
  type        = number
  default     = 1
  description = "Maximimum number of nodes unavailable during update"
}
