locals {
  albs = {
    for lb in var.load_balancers : lb.name => lb
    if lower(lb.type) == "alb"
  }

  nlbs = {
    for lb in var.load_balancers : lb.name => lb
    if lower(lb.type) == "nlb"
  }
}

resource "aws_lb" "alb_lb" {
  for_each = local.albs

  name               = "${var.deploy_id}-${each.key}-alb"
  internal           = each.value.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg["${var.deploy_id}-${each.key}-sg"]]
  subnets            = var.network_info.subnets.private

  enable_deletion_protection = false

  access_logs {
    enabled = var.access_logs.enabled
    bucket  = var.access_logs.s3_bucket
    prefix  = var.access_logs.s3_prefix
  }

  connection_logs {
    enabled = var.connection_logs.enabled
    bucket  = var.connection_logs.s3_bucket
    prefix  = var.connection_logs.s3_prefix
  }

  tags = {
    Name = "${var.deploy_id}-${each.key}-alb"
  }
}