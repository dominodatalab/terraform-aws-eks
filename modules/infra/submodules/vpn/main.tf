resource "aws_customer_gateway" "customer_gateway" {
  for_each = { for vpn in var.vpn_connections : vpn.name => vpn }

  ip_address = each.value.shared_ip
  type       = "ipsec.1"
  bgp_asn    = "65000"
  tags = {
    Name = each.value.name
  }
}

resource "aws_vpn_gateway" "this" {
  vpc_id = var.network_info.vpc_id
  tags = {
    Name = "${var.deploy_id}-vpn-gateway"
  }
}

resource "aws_vpn_gateway_attachment" "this" {
  vpc_id         = var.network_info.vpc_id
  vpn_gateway_id = aws_vpn_gateway.this.id
}

resource "aws_vpn_connection" "this" {
  for_each = aws_customer_gateway.customer_gateway

  customer_gateway_id = each.value.id
  vpn_gateway_id      = aws_vpn_gateway.this.id
  type                = "ipsec.1"
  static_routes_only  = true
  tags = {
    Name = "${each.key}-vpn-connection"
  }
}

locals {
  vpn_cidr_blocks = {
    for vpn in var.vpn_connections : vpn.name => {
      cidr_blocks = vpn.cidr_blocks
      vpn_id      = aws_vpn_connection.this[vpn.name].id
    }
  }

  flattened_vpn_cidr_block = merge([
    for vpn, data in local.vpn_cidr_blocks : {
      for cidr in data.cidr_blocks : cidr => data.vpn_id
    }
  ]...)
}

resource "aws_vpn_connection_route" "this" {
  for_each = local.flattened_vpn_cidr_block

  destination_cidr_block = each.key
  vpn_connection_id      = each.value
}


locals {
  route_table_ids = concat(var.network_info.route_tables.private, var.network_info.route_tables.pod)
}

resource "aws_vpn_gateway_route_propagation" "route_propagation" {
  count          = length(local.route_table_ids)
  vpn_gateway_id = aws_vpn_gateway.this.id
  route_table_id = local.route_table_ids[count.index]
}
