
variable "sshkey_prefix" {
  description = "Prefix for the AWS Secrets Manager secret names."
  type        = string
  default     = "example"
}

variable "public_key" {
  type        = string
  description = "Public Key for ec2 ssh connections"
}
