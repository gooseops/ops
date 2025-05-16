
resource "aws_amplify_app" "app" {
  name                 = var.name
  repository           = "https://github.com/${var.repo_owner}/${var.repo_name}"
  access_token         = var.github_token
  platform             = var.platform
  iam_service_role_arn = var.iam_role

  environment_variables = var.environment_variables

  build_spec = var.build_spec
}

resource "aws_amplify_branch" "branch" {
  app_id            = aws_amplify_app.app.id
  branch_name       = var.branch
  stage             = var.stage
  framework         = var.framework
  enable_auto_build = false
}

resource "aws_amplify_domain_association" "domain" {
  app_id      = aws_amplify_app.app.id
  domain_name = var.domain_name

  sub_domain {
    branch_name = aws_amplify_branch.branch.branch_name
    prefix      = var.sub_domain
  }
}

output "dns_records" {
  value = aws_amplify_domain_association.domain.certificate_verification_dns_record
}

output "amplify_app_id" {
  value = aws_amplify_app.app.id
}
