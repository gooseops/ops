resource "aws_route_table" "rt" {
  vpc_id = var.vpc_id
  tags   = var.tags
}

resource "aws_route_table_association" "rta" {
  for_each = toset(var.subnet_ids)

  subnet_id      = each.value
  route_table_id = aws_route_table.rt.id
}

resource "aws_route" "custom_routes" {
  for_each = { for idx, route in var.routes : idx => route }

  route_table_id            = aws_route_table.rt.id
  destination_cidr_block    = each.value.destination_cidr_block
  gateway_id                = lookup(each.value, "gateway_id", null)
  nat_gateway_id            = lookup(each.value, "nat_gateway_id", null)
  vpc_peering_connection_id = lookup(each.value, "vpc_peering_connection_id", null)
  transit_gateway_id        = lookup(each.value, "transit_gateway_id", null)
  network_interface_id      = lookup(each.value, "network_interface_id", null)
  egress_only_gateway_id    = lookup(each.value, "egress_only_gateway_id", null)
}
