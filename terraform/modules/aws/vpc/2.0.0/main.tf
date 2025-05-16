resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id

  lifecycle {
    prevent_destroy = false
  }

}

resource "aws_subnet" "subnet" {
  for_each = { for idx, subnet in var.subnets : idx => subnet }

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet-${each.key}"
  }

  depends_on = [aws_vpc.vpc]
}

resource "aws_route_table" "this" {
  vpc_id = aws_vpc.vpc.id

  depends_on = [aws_vpc.vpc]
}


resource "aws_route_table_association" "this" {
  for_each = { for index, subnet in var.subnets : index => subnet if subnet.is_public }

  subnet_id      = aws_subnet.subnet[each.key].id
  route_table_id = aws_route_table.this.id

  depends_on = [aws_vpc.vpc]
}

resource "aws_route" "init" {
  route_table_id         = aws_route_table.this.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

resource "aws_route" "custom_routes" {
  for_each = { for idx, route in var.routes : idx => route }

  route_table_id            = aws_route_table.this.id
  destination_cidr_block    = each.value.destination_cidr_block
  gateway_id                = lookup(each.value, "gateway_id", null)
  nat_gateway_id            = lookup(each.value, "nat_gateway_id", null)
  vpc_peering_connection_id = lookup(each.value, "vpc_peering_connection_id", null)
  transit_gateway_id        = lookup(each.value, "transit_gateway_id", null)
  network_interface_id      = lookup(each.value, "network_interface_id", null)
  egress_only_gateway_id    = lookup(each.value, "egress_only_gateway_id", null)
}
