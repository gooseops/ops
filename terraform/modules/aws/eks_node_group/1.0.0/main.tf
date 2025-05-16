
resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "eks-nodes-"
  image_id      = var.eks_ami
  instance_type = var.instance_type

  vpc_security_group_ids = var.security_group_ids

  tag_specifications {
    resource_type = "instance"
    tags = {
      "Name"                                      = "eks-node"
      "eks:nodegroup-name"                        = var.node_group_name
      "eks:cluster-name"                          = var.cluster_name
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.disk_size
      volume_type           = var.volume_type
      delete_on_termination = true
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -o xtrace
    /etc/eks/bootstrap.sh ${var.cluster_name}
  EOF
  )
}


resource "aws_eks_node_group" "node_group" {

  cluster_name    = var.cluster_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  node_group_name = var.node_group_name

  capacity_type = var.capacity_type
  labels        = var.node_labels

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  update_config {
    max_unavailable = var.max_unavailable
  }
}
