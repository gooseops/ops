
output "cluster_security_group_id" {
  value = aws_security_group.group.id
}

output "cluster_info" {
  value = aws_eks_cluster.cluster
}
