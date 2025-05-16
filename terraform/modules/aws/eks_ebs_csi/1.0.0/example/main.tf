module "eks_ebs_csi" {
  source = "../"

  eks_oidc_issuer        = "example-issuer"
  cluster_name           = "example-cluster"
  eks_csi_driver_version = "v1.41.0-eksbuild.1"
}
