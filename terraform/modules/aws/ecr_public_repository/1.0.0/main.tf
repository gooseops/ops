
resource "aws_ecrpublic_repository" "repository" {
  repository_name = var.repository_name
  catalog_data {
    architectures     = ["x86-64"]
    operating_systems = ["Linux"]
  }
}

data "aws_caller_identity" "current" {}

locals {
  arn_prefix       = split("/", data.aws_caller_identity.current.arn)[0]
  full_arns        = [for i in var.push_users : "${local.arn_prefix}/${i}"]
  total_push_users = concat([data.aws_caller_identity.current.arn], local.full_arns)
}

resource "aws_ecrpublic_repository_policy" "repo_policy" {
  repository_name = aws_ecrpublic_repository.repository.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRPushPolicy"
        Effect = "Allow"
        Principal = {
          AWS = local.total_push_users
        }
        Action = [
          "ecr-public:GetDownloadUrlForLayer",
          "ecr-public:BatchGetImage",
          "ecr-public:BatchCheckLayerAvailability",
          "ecr-public:PutImage",
          "ecr-public:InitiateLayerUpload",
          "ecr-public:UploadLayerPart",
          "ecr-public:CompleteLayerUpload"
        ]
      }
    ]
  })
}
