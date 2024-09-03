

resource "aws_customer_gateway" "customer_gateway" {
  ip_address = var.vpn_connection.shared_ip
  type       = "ipsec.1"
  bgp_asn    = "65000"
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

resource "aws_vpn_gateway_route_propagation" "route_propagation" {
  for_each = toset(concat(var.network_info.route_tables.private, var.network_info.route_tables.pod))

  vpn_gateway_id = aws_vpn_gateway.this.id
  route_table_id = each.value
}
