# AWS Elastic Kubernetes Service Cluster
This is a terraform module for creating all things necessary for an aws eks cluster

## Examples
Please see the `example` directory in each module version for ways the module can be used in a worlds directory

## Providers
See `providers.tf` of each release for minimum provider version this module supports.

- [aws](https://registry.terraform.io/providers/hashicorp/aws/latest)

## Resources
- `aws_launch_template`: AWS EC2 launch template for the instances that will be in the eks node group.
- `aws_eks_node_group`: AWS Elastic Kubernetes Service Node Group(s), a set of Kubernetes Nodes provisioned for running Kubernetes workloads

## Configuration
See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Releases
- 1.0.0: Initial Release - Moved eks node_group into its own module.
