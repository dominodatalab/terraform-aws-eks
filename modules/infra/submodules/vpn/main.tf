

resource "aws_customer_gateway" "customer_gateway" {
  ip_address = var.vpn_connection.shared_ip
  type       = "ipsec.1"
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
  customer_gateway_id = aws_customer_gateway.customer_gateway.id
  vpn_gateway_id      = aws_vpn_gateway.this.id
  type                = "ipsec.1"

  static_routes_only = true

  tags = {
    Name = "${var.deploy_id}-vpn-connection"
  }
}

resource "aws_vpn_connection_route" "this" {
  destination_cidr_block = var.vpn_connection.cidr_block
  vpn_connection_id      = aws_vpn_connection.this.id
}

locals {
  route_table_ids = concat(var.network_info.route_tables.private, var.network_info.route_tables.pod)
}

resource "aws_vpn_gateway_route_propagation" "route_propagation" {
  count          = length(local.route_table_ids)
  vpn_gateway_id = aws_vpn_gateway.this.id
  route_table_id = local.route_table_ids[count.index]
}
