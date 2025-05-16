# AWS OIDC and EBS_CSI addon
This is a terraform module for creating all things necessary for adding OIDC and EBS_CSI addon to an EKS cluster.

## Examples
Please see the `example` directory in each module version for ways the module can be used in a worlds directory

## Providers
See `providers.tf` of each release for minimum provider version this module supports.

- [aws](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [tls](https://registry.terraform.io/providers/hashicorp/tls/latest)

## Data

- `tls_certificate`: The tls certificate from the kubernetes issuer for OIDC

## Resources

- `aws_iam_openid_connect_provider`: AWS OIDC Provider linking Kubernetes Service Account and IAM role
- `aws_iam_role`: AWS IAM Role specifically designed for EBS CSI Driver addon
- `aws_iam_role_policy_attachment`: AWS IAM Role Attachment specifically designed for EBS CSI Driver addon
- `aws_eks_addon`: AWS EKS addon CSI driver to allow kubernetes to dynamically provision EBS volumes and attach them to pods

## Configuration
See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Releases
- 1.0.0: Initial Release - Moved OIDC and EBS_CSI addon into its own module.
