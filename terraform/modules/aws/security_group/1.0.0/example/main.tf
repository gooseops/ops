module "example_sg" {
  source = "../"

  name   = "example_sg"
  vpc_id = "example_vpc_id"
  ingress_rules = [
    {
      name        = "http"
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
    }
  ]
}
