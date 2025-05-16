# AWS Elastic Kubernetes Service Cluster
This is a terraform module for creating all things necessary for an aws eks cluster

## Example usage
The below files would be placed in the root/world module that is calling all submodules.

`eks_cluster.tf`
```HCL
module "example_eks_cluster" {
  source = "../"

  cluster_name     = "example"
  cluster_role_arn = "example:eks_role_arn"
  vpc_id           = "example-vpcid"
  subnet_ids = [
    "example-subnetid1",
    "example-subnetid2"
  ]
  kubernetes_version = "1.29"
  node_role_arn      = "example:node_role_arn"

  node_groups = [
    ({
      node_group_name = "example_node_group"
      instance_types  = ["t3.medium", "t3.large", "t3.small"]
      capacity_type   = "ON_DEMAND"
      node_labels = ({
        function = "example"
      })
      desired_size    = 1
      max_size        = 2
      min_size        = 1
      max_unavailable = 1
    })
  ]

  depends_on = ["example-dependency-1", "example-dependency-2"]
}

```
`providers.tf`
```HCL
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }
  }
}

provider "aws" {
    alias = "us-east-1"
    region = "us-east-1"
}

provider "aws" {
    alias = "us-east-2"
    region = "us-east-2"
}
```
## Providers
See `providers.tf` of each release for minimum provider version this module supports.

- [aws](https://registry.terraform.io/providers/hashicorp/aws/latest)

## Resources
- `aws_eks_cluster`: AWS Elastic Kubernetes Service Cluster Kubernetes backplane
- `aws_security_group`: AWS Security Group for managing and limiting public internet access to the EKS Cluster
- `aws_eks_node_group`: AWS Elastic Kubernetes Service Node Group(s), a set of Kubernetes Nodes provisioned for running Kubernetes workloads
- `aws_iam_openid_connect_provider`: AWS OIDC Provider linking Kubernetes Service Account and IAM role
- `aws_iam_role`: AWS IAM Role specifically designed for EBS CSI Driver addon
- `aws_iam_role_policy_attachment`: AWS IAM Role Attachment specifically designed for EBS CSI Driver addon
- `aws_eks_addon`: AWS EKS addon CSI driver to allow kubernetes to dynamically provision EBS volumes and attach them to pods

## Configuration
See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Releases
- 1.0.0: Initial Release
- 2.0.0: Moved OIDC, EBS_CSI addon, node group, and security group into their own modules.
