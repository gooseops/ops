output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr_block" {
  value = aws_vpc.vpc.cidr_block
}

output "subnet_ids" {
  value = { for idx, subnet in aws_subnet.subnet : idx => subnet.id }
}

output "subnet_cidr_blocks" {
  value = { for idx, subnet in aws_subnet.subnet : idx => subnet.cidr_block }
}
