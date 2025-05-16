module "example_aws_secret" {
  source = "../"

  secret_name   = "example"
  secret_string = "foobar"
}
