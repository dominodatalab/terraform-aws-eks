
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

  route_table_ids = concat(local.public_route_table_ids, local.private_route_table_ids, local.pod_route_table_ids)

  tags = {
    "Name" = "${var.deploy_id}-s3"
  }
}

resource "aws_vpc_endpoint" "s3_interface" {
  count               = local.create_vpc ? 1 : 0
  vpc_id              = aws_vpc.this[0].id
  service_name        = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for s in aws_subnet.pod : s.id]

  route_table_ids = concat(local.public_route_table_ids, local.private_route_table_ids, local.pod_route_table_ids)

  tags = {
    "Name" = "${var.deploy_id}-s3"
  }
}

data "aws_prefix_list" "s3" {
  count          = local.create_vpc ? 1 : 0
  prefix_list_id = aws_vpc_endpoint.s3[0].prefix_list_id
}

resource "aws_security_group" "ecr_endpoint" {
  count       = local.create_ecr_endpoint ? 1 : 0
  name        = "${var.deploy_id}-ecr"
  description = "ECR Endpoint security group"
  vpc_id      = aws_vpc.this[0].id

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    "Name" = "${var.deploy_id}-ecr"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count               = local.create_ecr_endpoint ? 1 : 0
  vpc_id              = aws_vpc.this[0].id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.pod : s.id]

  security_group_ids = [
    aws_security_group.ecr_endpoint[0].id,
  ]

  tags = {
    "Name" = "${var.deploy_id}-ecr-dkr"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  count               = local.create_ecr_endpoint ? 1 : 0
  vpc_id              = aws_vpc.this[0].id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.pod : s.id]

  security_group_ids = [
    aws_security_group.ecr_endpoint[0].id,
  ]

  tags = {
    "Name" = "${var.deploy_id}-ecr-api"
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
