variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "cluster_role_arn" {
  type        = string
  description = "The ARN for the AWS EKS Cluster role"
}

variable "subnet_ids" {
  type        = list(string)
  default     = []
  description = "List of subnet IDs where the EKS cluster will be created"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.29"
  description = "Kubernetes Version"
}
