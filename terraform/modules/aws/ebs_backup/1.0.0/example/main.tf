module "example_backup" {
  source = "../"

  iam_role_arn = "<<iam arn here>>"
  instance_arn = "<<instance arn here>>"
}
