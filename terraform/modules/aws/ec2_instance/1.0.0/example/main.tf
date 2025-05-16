module "example_ec2" {
  source = "../"

  subnet_id          = ["example_subnet_id"]
  security_group_ids = ["example-id1", "example-id2"]
  role               = "example"

}
