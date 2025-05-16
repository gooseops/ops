
variable "name" {
  type        = string
  default     = "example"
  description = "Name of all resources created by this backup module"
}

variable "schedule" {
  type        = string
  default     = "cron(0 3 * * ? *)"
  description = "The schedule for when bacups are taken"
}

variable "backup_retention" {
  type        = number
  default     = 7
  description = "The number of days to retain backups"
}

variable "iam_role_arn" {
  type        = string
  description = "ARN of IAM role that has permissions for creating backups"
}

variable "instance_arn" {
  type        = string
  description = "AWS Arn of the EC2 instance being backed up"
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "Destroy recovery points with vault without throwing error."
}
