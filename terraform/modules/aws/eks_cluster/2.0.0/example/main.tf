module "example_eks_cluster" {
  source = "../"

  cluster_name     = "example"
  cluster_role_arn = "example:eks_role_arn"
  subnet_ids = [
    "example-subnetid1",
    "example-subnetid2"
  ]
  kubernetes_version = "1.32"
  depends_on         = ["example-dependency-1", "example-dependency-2"]
}
