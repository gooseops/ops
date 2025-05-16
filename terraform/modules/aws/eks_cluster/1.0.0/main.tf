
resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version
  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [aws_security_group.group.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }
}
