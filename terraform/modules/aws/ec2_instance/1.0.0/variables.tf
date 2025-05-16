variable "name" {
  type        = string
  default     = "example"
  description = "The name of the virtual machine"
}

variable "role" {
  type        = string
  description = "The Ansible role off this server"
}

variable "instance_type" {
  description = "The type of instance to create."
  type        = string
  default     = "t3.micro"
}

variable "volume_size" {
  description = "Size of the root volume on the instance"
  type        = string
  default     = "8"
}

variable "ami_id" {
  description = "The AMI ID for the instance."
  type        = string
  default     = "ami-0862be96e41dcbf74" # Example AMI ID (Amazon Linux 2)
}

variable "key_name" {
  description = "The name of the key pair to use for the instance."
  type        = string
  default     = "my-key-pair"
}

variable "admin_user" {
  type        = string
  default     = "ubuntu"
  description = "Username of the administrative ec2 user"
}

variable "subnet_id" {
  type        = string
  description = "The AWS subnet ID of the subnet to launch this instance in"
}

variable "security_group_ids" {
  type        = list(string)
  description = "The Security Group IDs to attach to the instance."
}

variable "needs_eip" {
  type        = bool
  description = "Whether or not the AWS instance needs an Elastic IP"
  default     = false
}
