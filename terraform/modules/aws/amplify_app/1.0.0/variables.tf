variable "name" {
  type        = string
  description = "Name of the Amplify app"
}

variable "github_token" {
  type        = string
  description = "Github token with access to the repo"
}

variable "repo_owner" {
  type        = string
  description = "GitHub repository owner"
}

variable "repo_name" {
  type        = string
  description = "Name of the GitHub repository"
}

variable "branch" {
  type        = string
  default     = "main"
  description = "Branch to deploy from"
}

variable "platform" {
  type        = string
  default     = "WEB"
  description = "Amplify platform ('WEB' or 'WEB_COMPUTE')"
}

variable "iam_role" {
  type        = string
  description = "IAM role for AWS Amplify"
}

variable "environment_variables" {
  type        = map(string)
  default     = null
  description = "Key value pairs for needed environment variables"
}

variable "stage" {
  type        = string
  description = "Describes the current stage for the branch. Valid values: PRODUCTION, BETA, DEVELOPMENT, EXPERIMENTAL, PULL_REQUEST."
}

variable "build_spec" {
  type        = string
  description = "Build spec for amplify build and deploy commands"
}

variable "framework" {
  type        = string
  description = "Type of frontend framework"
}

variable "domain_name" {
  type        = string
  description = "Root domain name"
}

variable "sub_domain" {
  type        = string
  default     = ""
  description = "Sub domain prefix that comes before the root domain"
}
