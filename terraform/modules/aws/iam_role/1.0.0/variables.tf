variable "role_name" {
  type        = string
  default     = "example-role"
  description = "Name of the role"
}

variable "assume_role_policy" {
  type        = string
  default     = <<-EOT
  {
    "Statement": [{
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }],
    "Version": "2012-10-17"
  }
  EOT
  description = "An assume role policy indicating who or what can assume(use) this IAM role"
}

variable "policy_attachment_arns" {
  type        = list(string)
  default     = []
  description = "The policy arn that needs to be attached to the role"
}
