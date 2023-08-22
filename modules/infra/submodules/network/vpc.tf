
data "aws_vpc" "provided" {
  count = local.create_vpc ? 0 : 1
  id    = var.network.vpc.id
  # lifecycle {
  #   postcondition {
  #     condition     = self.state == "available"
  #     error_message = "VPC: ${self.id} is not available."
  #   }
  # }

}


resource "aws_vpc" "this" {
  count                            = local.create_vpc ? 1 : 0
  assign_generated_ipv6_cidr_block = false
  cidr_block                       = var.network.cidrs.vpc
  enable_dns_hostnames             = true
  enable_dns_support               = true
  tags = {
    "Name" = var.deploy_id
  }
}


resource "aws_vpc_ipv4_cidr_block_association" "pod_cidr" {
  count      = local.create_vpc && var.network.use_pod_cidr ? 1 : 0
  vpc_id     = aws_vpc.this[0].id
  cidr_block = var.network.cidrs.pod
}


resource "aws_default_security_group" "default" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.this[0].id
}

resource "aws_vpc_endpoint" "s3" {
  count             = local.create_vpc ? 1 : 0
  vpc_id            = aws_vpc.this[0].id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    [for s in aws_route_table.public : s.id],
    [for s in aws_route_table.private : s.id],
    [for s in aws_route_table.pod : s.id]
  )

  tags = {
    "Name" = "${var.deploy_id}-s3"
  }
}

data "aws_network_acls" "default" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.this[0].id

  filter {
    name   = "default"
    values = ["true"]
  }
}

resource "aws_default_network_acl" "default" {
  count                  = local.create_vpc ? 1 : 0
  default_network_acl_id = one(data.aws_network_acls.default[0].ids)

  egress {
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = "0"
    icmp_code  = "0"
    icmp_type  = "0"
    protocol   = "-1"
    rule_no    = "100"
    to_port    = "0"
  }

  ingress {
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = "0"
    icmp_code  = "0"
    icmp_type  = "0"
    protocol   = "-1"
    rule_no    = "100"
    to_port    = "0"
  }

  subnet_ids = concat(
    [for s in aws_subnet.public : s.id],
    [for s in aws_subnet.private : s.id],
    [for s in aws_subnet.pod : s.id]
  )

  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

resource "aws_flow_log" "this" {
  count                    = local.create_vpc && var.flow_log_bucket_arn != null ? 1 : 0
  log_destination          = var.flow_log_bucket_arn["arn"]
  vpc_id                   = aws_vpc.this[0].id
  max_aggregation_interval = 600
  log_destination_type     = "s3"
  traffic_type             = "REJECT"
}
