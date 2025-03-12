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
  # Get connection type for each VPN
  vpn_connection_types = {
    for vpn in var.vpn_connections : vpn.name => vpn.connection_type
  }

  # For full VPN connections, use the provided CIDR blocks
  vpn_full_cidr_blocks = {
    for vpn in var.vpn_connections : vpn.name => {
      cidr_blocks = vpn.cidr_blocks
      vpn_id      = aws_vpn_connection.this[vpn.name].id
      type        = coalesce(vpn.connection_type, "full")
    } if coalesce(vpn.connection_type, "full") == "full"
  }

  # For public-only VPN connections, use the provided CIDR blocks
  vpn_public_only_cidr_blocks = {
    for vpn in var.vpn_connections : vpn.name => {
      cidr_blocks = vpn.cidr_blocks
      vpn_id      = aws_vpn_connection.this[vpn.name].id
      type        = "public_only"
    } if coalesce(vpn.connection_type, "full") == "public_only"
  }

  # Combine both types for VPN connection routes
  vpn_cidr_blocks = merge(local.vpn_full_cidr_blocks, local.vpn_public_only_cidr_blocks)

  # Flatten CIDR blocks for route creation
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
  # Get route tables based on connection type
  public_route_tables = var.network_info.route_tables.public
  private_route_tables = var.network_info.route_tables.private
  pod_route_tables = var.network_info.route_tables.pod
  
  # Determine which route tables need route propagation based on VPN connection types
  route_tables_full_vpn = concat(
    local.public_route_tables != null ? local.public_route_tables : [], 
    local.private_route_tables != null ? local.private_route_tables : [],
    local.pod_route_tables != null ? local.pod_route_tables : []
  )
  
  route_tables_public_only_vpn = local.public_route_tables != null ? local.public_route_tables : []
  
  # Check if we have any vpn of each type
  has_full_vpn = length(local.vpn_full_cidr_blocks) > 0
  has_public_only_vpn = length(local.vpn_public_only_cidr_blocks) > 0
  
  # Create a mapping of route tables to VPN connections
  route_table_propagation_map = {
    "full" = local.has_full_vpn ? local.route_tables_full_vpn : []
    "public_only" = local.has_public_only_vpn ? local.route_tables_public_only_vpn : []
  }
  
  # Final list of route tables based on the VPN types that exist
  route_table_ids = distinct(flatten([
    local.has_full_vpn ? local.route_tables_full_vpn : [],
    local.has_public_only_vpn ? local.route_tables_public_only_vpn : []
  ]))
}

resource "aws_vpn_gateway_route_propagation" "route_propagation" {
  count          = length(local.route_table_ids)
  vpn_gateway_id = aws_vpn_gateway.this.id
  route_table_id = local.route_table_ids[count.index]
}