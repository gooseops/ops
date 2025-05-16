
resource "aws_eks_node_group" "node_group" {
  for_each = { for ng in var.node_groups : ng.node_group_name => ng }

  cluster_name  = aws_eks_cluster.cluster.name
  node_role_arn = var.node_role_arn
  subnet_ids    = var.subnet_ids

  node_group_name = each.value.node_group_name
  instance_types  = each.value.instance_types
  capacity_type   = each.value.capacity_type
  labels          = each.value.node_labels
  ami_type        = each.value.ami_type
  disk_size       = each.value.disk_size

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  update_config {
    max_unavailable = each.value.max_unavailable
  }
}
