
resource "aws_key_pair" "ssh_key" {
  key_name   = "${var.sshkey_prefix}-key"
  public_key = var.public_key
}
