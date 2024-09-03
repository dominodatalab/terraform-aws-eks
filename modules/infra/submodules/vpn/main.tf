

resource "aws_customer_gateway" "customer_gateway" {
  ip_address = var.customer_info.shared_ip
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
  destination_cidr_block = var.customer_info.cidr_block
  vpn_connection_id      = aws_vpn_connection.this.id
}

resource "aws_vpn_gateway_route_propagation" "route_propagation" {
  for_each = {
    for subnet in concat(var.network_info.subnets.private, var.network_info.subnets.pod) : subnet.name => subnet.subnet_id
  }

  vpn_gateway_id = aws_vpn_gateway.this.id
  route_table_id = each.value
}