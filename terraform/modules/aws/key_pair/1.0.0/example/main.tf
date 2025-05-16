module "example_aws_key_pair" {
  source = "../"

  sshkey_prefix = "example"
  public_key    = "public key content here"
}
