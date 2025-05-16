
variable "secret_name" {
  description = "The name of the secret."
  type        = string
}

variable "secret_description" {
  description = "The description of the secret."
  type        = string
  default     = "A secret created by Terraform."
}

variable "recovery_window_in_days" {
  type        = number
  default     = 0
  description = <<EOF
    (Optional) Number of days that AWS Secrets Manager waits before it can delete the 
    secret. This value can be 0 to force deletion without recovery or range from 7 to 
    30 days. The default value is 30. 
  EOF
}

variable "secret_string" {
  description = "The secret string to be stored."
  type        = string
}
