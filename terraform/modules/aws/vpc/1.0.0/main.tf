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

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  depends_on = [aws_vpc.vpc]
}


resource "aws_route_table_association" "public" {
  for_each = { for index, subnet in var.subnets : index => subnet if subnet.is_public }

  subnet_id      = aws_subnet.subnet[each.key].id
  route_table_id = aws_route_table.public.id

  depends_on = [aws_vpc.vpc]
}
