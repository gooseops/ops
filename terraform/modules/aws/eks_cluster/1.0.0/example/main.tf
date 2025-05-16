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
