output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "subnet_ids" {
  value = { for idx, subnet in aws_subnet.subnet : idx => subnet.id }
}

output "subnet_cidr_blocks" {
  value = { for idx, subnet in aws_subnet.subnet : idx => subnet.cidr_block }
}

output "vpc_rt_id" {
  value = aws_route_table.public.id
}
