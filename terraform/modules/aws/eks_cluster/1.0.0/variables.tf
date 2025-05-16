variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "cluster_role_arn" {
  type        = string
  description = "The ARN for the AWS EKS Cluster role"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC where the EKS cluster will be created"
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

variable "node_role_arn" {
  type        = string
  description = "The AWS ARN of the node group role for provisioning EKS nodes."
}

variable "node_groups" {
  type = list(object({
    node_group_name = string
    instance_types  = optional(list(string))
    capacity_type   = optional(string, "ON_DEMAND")
    node_labels     = object({})
    ami_type        = optional(string, null)
    disk_size       = optional(number, null)
    desired_size    = optional(number, 1)
    max_size        = optional(number, 2)
    min_size        = optional(number, 1)
    max_unavailable = optional(number, 1)
  }))
  description = <<EOF
    Node Group configuration options. See AWS Terraform provider for `aws_eks_node_group` 
    for more information
  EOF
}

variable "eks_csi_driver_version" {
  type        = string
  default     = "v1.30.0-eksbuild.1"
  description = <<EOF
    Version of AWS EKS EBS CSI driver addon 
    `aws eks describe-addon-versions --addon-name aws-ebs-csi-driver --region us-east-2`
  EOF
}
