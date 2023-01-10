resource "aws_vpc" "this" {
  assign_generated_ipv6_cidr_block = false
  cidr_block                       = var.cidr
  enable_dns_hostnames             = true
  enable_dns_support               = true
  tags = {
    "Name" = var.deploy_id
  }
}

locals {
  vpc_id = aws_vpc.this.id
}

resource "aws_vpc_ipv4_cidr_block_association" "pod_cidr" {
  count      = var.use_pod_cidr ? 1 : 0
  vpc_id     = aws_vpc.this.id
  cidr_block = var.pod_cidr
}

resource "aws_default_security_group" "default" {
  vpc_id = local.vpc_id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = local.vpc_id
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
  vpc_id = local.vpc_id

  filter {
    name   = "default"
    values = ["true"]
  }
}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = one(data.aws_network_acls.default.ids)

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
  count                    = var.flow_log_bucket_arn != null ? 1 : 0
  log_destination          = var.flow_log_bucket_arn["arn"]
  vpc_id                   = local.vpc_id
  max_aggregation_interval = 600
  log_destination_type     = "s3"
  traffic_type             = "REJECT"
}
