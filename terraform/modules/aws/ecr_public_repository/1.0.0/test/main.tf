module "test_public_ecr" {
  providers = {
    aws = aws.us-east-1
  }

  source          = "../"
  repository_name = "foo"
}
