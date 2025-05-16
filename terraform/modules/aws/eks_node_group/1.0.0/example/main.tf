module "example_eks_cluster" {
  source = "../"

  cluster_name = "example"
  subnet_ids = [
    "example-subnetid1",
    "example-subnetid2"
  ]
  security_group_ids = ["example-sg-id1", "example-sg-id2"]
  eks_ami            = "ami-0d93f9d827f779211"
  node_role_arn      = "example:node_role_arn"
  node_group_name    = "example_node_group"
  instance_type      = "t3.medium"
  capacity_type      = "ON_DEMAND"
  node_labels        = {}
  disk_size          = 30

  desired_size    = 1
  max_size        = 2
  min_size        = 1
  max_unavailable = 1

  depends_on = ["example-dependency-1", "example-dependency-2"]
}
