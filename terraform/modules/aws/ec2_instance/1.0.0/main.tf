
data "template_file" "cloud_init" {
  template = file("${path.module}/templates/cloud-config.yaml")

  vars = {
    admin_user = var.admin_user
  }
}

resource "aws_instance" "instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  root_block_device {
    volume_size = var.volume_size
  }

  key_name  = var.key_name
  subnet_id = var.subnet_id

  vpc_security_group_ids = var.security_group_ids

  user_data = data.template_file.cloud_init.rendered
  tags = {
    Name = var.name
    Role = var.role
  }
}

resource "aws_eip" "eip" {
  count    = var.needs_eip ? 1 : 0
  instance = aws_instance.instance.id
  domain   = "vpc"
}
