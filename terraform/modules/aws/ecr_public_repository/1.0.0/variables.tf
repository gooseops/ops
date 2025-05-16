variable "repository_name" {
  type        = string
  default     = "foo"
  description = <<EOF
        Image name and consequently, the name of the 
        repository.
    EOF
}

variable "push_users" {
  type        = list(string)
  default     = []
  description = "List of IAM user ARNs allowed to push to the ECR Public repository."
}
