module "frontend" {
  source = "../"

  name         = "example-app"
  repo_owner   = "example-owner"
  repo_name    = "example-repo"
  branch       = "main"
  github_token = "example-token"
  iam_role     = example.arn
  stage        = "PRODUCTION"
  framework    = "Next.js - SSR"
  platform     = "WEB_COMPUTE"
  domain_name  = "app.example.com"
  environment_variables = {
    "FOO" = "bar"
  }

  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm install -g pnpm
            - pnpm install
        build:
          commands:
            - pnpm run build
      artifacts:
        baseDirectory: .next
        files:
          - '**/*'
      cache:
        paths:
          - .next/cache/**/*
          - node_modules/**/*
  EOT
}
